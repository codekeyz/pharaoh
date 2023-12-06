// ignore: depend_on_referenced_packages
import 'package:meta/meta.dart';
import 'package:pharaoh/pharaoh.dart';

import 'node.dart';
import '../route/action.dart';
import '../parametric/definition.dart';
import '../parametric/utils.dart';

// ignore: constant_identifier_names
const BASE_PATH = '/';

class RouterConfig {
  final bool caseSensitive;
  final bool ignoreTrailingSlash;
  final bool ignoreDuplicateSlashes;

  const RouterConfig({
    this.caseSensitive = true,
    this.ignoreTrailingSlash = true,
    this.ignoreDuplicateSlashes = true,
  });
}

class Spanner {
  final RouterConfig config;
  late final Node _root;

  Node get root => _root;

  int _currentIndex = 0;

  int get _nextIndex => _currentIndex + 1;

  Spanner({this.config = const RouterConfig()}) : _root = StaticNode(BASE_PATH);

  void on(HTTPMethod method, String path, HandlerFunc handler) {
    _on(
      path,
      method,
      (index: _nextIndex, value: handler),
    );

    _currentIndex = _nextIndex;
  }

  /// Given the current segment in a route, this method figures
  /// out which node to create as a child to the current root node [node]
  ///
  /// TLDR -> we figure out which node to create and when we find or create that node,
  /// it then becomes our root node.
  ///
  /// - eg1: when given `users` in `/users`
  /// we will attempt searching for a child, if not found, will create
  /// a new [StaticNode] on the current root [node] and then return that.
  ///
  ///- eg2: when given `<userId>` in `/users/<userId>`
  ///we will find a static child `users` or create one, then proceed to search
  ///for a [ParametricNode] on the current root [node]. If found, we fill add a new
  ///definition, or create a new [ParametricNode] with this definition.
  Node _computeNode(
    Node node,
    String routePart,
    HTTPMethod method,
    IndexedHandler handler, {
    bool isLastSegment = false,
    required String fullPath,
  }) {
    String part = routePart;
    if (!config.caseSensitive) part = part.toLowerCase();

    final key = _getNodeKey(part);

    var child = node.children[part];
    if (child != null) {
      return node.addChildAndReturn(key, child);
    } else {
      if (part.isStatic) {
        return node.addChildAndReturn(key, StaticNode(key));
      } else if (part.isWildCard) {
        if (!isLastSegment) {
          throw ArgumentError.value(fullPath, null,
              'Route definition is not valid. Wildcard must be the end of the route');
        }

        return node.addChildAndReturn(key, WildcardNode());
      }

      final paramNode = node.paramNode;
      if (paramNode == null) {
        final defn = ParameterDefinition.from(routePart, terminal: isLastSegment);
        if (isLastSegment) defn.addHandler(method, handler);

        return node.addChildAndReturn(key, ParametricNode(defn));
      }

      final defn = ParameterDefinition.from(routePart, terminal: isLastSegment);
      if (isLastSegment) defn.addHandler(method, handler);

      return node.addChildAndReturn(key, paramNode..addNewDefinition(defn));
    }
  }

  void _on(String path, HTTPMethod method, IndexedHandler handler) {
    path = _cleanPath(path);
    Node rootNode = _root;

    if (path == BASE_PATH) {
      (rootNode as StaticNode)
        ..addHandler(method, handler)
        ..terminal = true;
      return;
    }

    final pathSegments = _getRouteSegments(path);
    for (int i = 0; i < pathSegments.length; i++) {
      final segment = pathSegments[i];

      rootNode = _computeNode(
        rootNode,
        segment,
        method,
        handler,
        fullPath: path,
        isLastSegment: i == (pathSegments.length - 1),
      );
    }

    /// parametric nodes being terminal is determined its definitions
    if (rootNode is StaticNode || rootNode is WildcardNode) {
      (rootNode as StaticNode)
        ..addHandler(method, handler)
        ..terminal = true;
    }
  }

  RouteResult? lookup(HTTPMethod method, String path, {bool debug = false}) {
    Node rootNode = _root;

    Map<String, dynamic> resolvedParams = {};
    List<IndexedHandler> wildcardHandlers = [];

    List<HandlerFunc> getResults(List<IndexedHandler> handlers) {
      final resultingHandlers = [
        ...handlers,
        ...wildcardHandlers,
      ]..sort((a, b) => a.index.compareTo(b.index));

      return resultingHandlers
          .where((e) => e.value != null)
          .map((e) => e.value!)
          .toList();
    }

    if (path == BASE_PATH) {
      rootNode as StaticNode;
      final wc = rootNode.wildcardNode;
      if (wc != null) wildcardHandlers.addAll(wc.getActions(method));
      return RouteResult(
        resolvedParams,
        getResults(rootNode.getActions(method)),
      );
    }

    final debugLog = StringBuffer("\n");

    void devlog(String message) {
      if (!debug) return;
      debugLog.writeln(message.toLowerCase());
      print(debugLog);
    }

    String route = _cleanPath(path);

    devlog('Finding node for ---------  ${method.name} $route ------------\n');

    final routeSegments = _getRouteSegments(route);

    for (int i = 0; i < routeSegments.length; i++) {
      final String currPart = routeSegments[i];

      var routePart = currPart;
      if (!config.caseSensitive) routePart = routePart.toLowerCase();

      final hasChild = rootNode.hasChild(routePart);
      final isLastPart = i == (routeSegments.length - 1);

      final wildcard = rootNode.wildcardNode;
      if (wildcard != null) {
        final handlers = wildcard.getActions(method);
        wildcardHandlers.addAll(handlers);
      }

      void useWildcard(WildcardNode wildcard) {
        resolvedParams['*'] = routeSegments.sublist(i).join('/');
        rootNode = wildcard;
      }

      if (hasChild) {
        rootNode = rootNode.getChild(routePart);
        devlog('- Found Static for             ->              $routePart');
      } else {
        final parametricNode = rootNode.paramNode;
        if (parametricNode == null) {
          devlog('x Found no static node for part       ->         $routePart');
          devlog('x Route is not registered             ->         $route');

          final wc = rootNode.wildcardNode;
          if (wc == null) return null;

          useWildcard(wc);
          break;
        }

        final hasChild = parametricNode.hasChild(routePart);
        if (hasChild) {
          devlog('- Found Static for             ->              $routePart');
          rootNode = parametricNode.getChild(routePart);
          continue;
        }

        devlog('- Finding Defn for $routePart        -> terminal?    $isLastPart');

        final definition = parametricNode.findMatchingDefinition(
          method,
          routePart,
          shouldBeTerminal: isLastPart,
        );

        devlog('    * parametric defn:         ${definition.toString()}');

        if (definition == null) {
          final wc = rootNode.wildcardNode;
          if (wc != null) {
            useWildcard(wc);
          } else if (parametricNode.definitions.length == 1) {
            final definition = parametricNode.definitions.first;
            if (definition is CompositeParameterDefinition) break;

            final remainingPath = routeSegments.sublist(i).join('/');
            final name = parametricNode.definitions.first.name;
            resolvedParams[name] = remainingPath;

            final handlers = definition.getActions(method);
            return RouteResult(resolvedParams, getResults(handlers), actual: definition);
          }
          break;
        }

        devlog('- Found defn for route part    ->              $routePart');

        final params = definition.resolveParams(currPart);
        resolvedParams.addAll(params);
        rootNode = parametricNode;

        if (isLastPart && definition.terminal) {
          final handlers = definition.getActions(method);
          return RouteResult(
            resolvedParams,
            getResults(handlers),
            actual: definition,
          );
        }
      }
    }

    if (!rootNode.terminal) return null;

    final List<IndexedHandler> handlers = switch (rootNode.runtimeType) {
      StaticNode => (rootNode as StaticNode).getActions(method),
      WildcardNode => (rootNode as WildcardNode).getActions(method),
      _ => [],
    };

    return RouteResult(resolvedParams, getResults(handlers), actual: rootNode);
  }

  void printTree() {
    _printNode(_root, '$BASE_PATH ');
  }

  void _printNode(Node node, String prefix) {
    if (node.terminal) print(prefix);

    node.children.forEach((char, node) {
      String prefixR = '$prefix$char';
      if (node.hasChildren) prefixR += ' / ';

      return _printNode(node, prefixR);
    });
  }

  String _cleanPath(String path) {
    if (!path.startsWith(BASE_PATH)) {
      throw ArgumentError.value(path, null, 'Route registration must start with `/`');
    }
    if (path.length == 1) return path;

    if (config.ignoreDuplicateSlashes) {
      path = path.replaceAll(RegExp(r'/+'), '/');
    }
    if (config.ignoreTrailingSlash) {
      path = path.replaceAll(RegExp(r'/+$'), '');
    }
    return path.substring(1);
  }

  List<String> _getRouteSegments(String route) => route.split('/');

  String _getNodeKey(String part) => part.isParametric ? '<:>' : part;
}

class RouteResult {
  final Map<String, dynamic> params;
  final List<HandlerFunc> handlers;

  @visibleForTesting
  final dynamic actual;

  const RouteResult(
    this.params,
    this.handlers, {
    this.actual,
  });
}
