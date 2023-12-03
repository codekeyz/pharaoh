// ignore: depend_on_referenced_packages
import 'package:meta/meta.dart';
import 'package:pharaoh/pharaoh.dart';

import 'node.dart';
import '../route/action.dart';
import '../parametric/definition.dart';
import '../parametric/utils.dart';

class RouterConfig {
  final bool caseSensitive;
  final bool ignoreTrailingSlash;
  final bool ignoreDuplicateSlashes;
  final String basePath;

  const RouterConfig({
    this.caseSensitive = true,
    this.ignoreTrailingSlash = true,
    this.ignoreDuplicateSlashes = true,
    this.basePath = '/',
  });
}

class Spanner {
  final RouterConfig config;
  late final Node _root;

  int _currentIndex = 0;

  Spanner({this.config = const RouterConfig()})
      : _root = StaticNode(config.basePath);

  void on(HTTPMethod method, String path, RouteHandler handler) {
    _currentIndex++;

    return _on(
      path,
      RouteAction(handler, method: method, index: _currentIndex),
    );
  }

  /// Given the current segment in a route, this method figures
  /// out which node to create as a child to the current root node [root]
  ///
  /// TLDR -> we figure out which node to create and when we find or create that node,
  /// it then becomes our root node.
  /// - eg1: when given `users` in `/users`
  /// we will attempt searching for a child, if not found, will create
  /// a new [StaticNode] on the current root [root] and then return that.
  ///
  ///- eg2: when given `<userId>` in `/users/<userId>`
  ///we will find a static child `users` or create one, then proceed to search
  ///for a [ParametricNode] on the current root [root]. If found, we fill add a new
  ///definition, or create a new [ParametricNode] with this definition.
  Node _computeNode(
    Node root,
    String routePart, {
    bool isLastSegment = false,
    required String fullPath,
    required RouteAction action,
  }) {
    String part = routePart;
    if (!config.caseSensitive) part = part.toLowerCase();

    final key = part.isParametric ? '<:>' : part;

    var child = root.children[part];
    if (child != null) {
      return root.addChildAndReturn(key, child);
    } else {
      if (part.isStatic) {
        return root.addChildAndReturn(key, StaticNode(key));
      } else if (part.isWildCard) {
        if (!isLastSegment) {
          throw ArgumentError.value(fullPath, null,
              'Route definition is not valid. Wildcard must be the end of the route');
        }

        return root.addChildAndReturn(key, WildcardNode());
      }

      final paramNode = root.paramNode;
      if (paramNode == null) {
        final defn =
            ParameterDefinition.from(routePart, terminal: isLastSegment);
        if (isLastSegment) defn.addAction(action);

        return root.addChildAndReturn(key, ParametricNode(defn));
      }

      final defn = ParameterDefinition.from(routePart, terminal: isLastSegment);
      if (isLastSegment) defn.addAction(action);

      return root.addChildAndReturn(key, paramNode..addNewDefinition(defn));
    }
  }

  void _on(String path, RouteAction action) {
    path = _cleanPath(path);
    Node root = _root;

    final pathSegments = path == '/' ? ['/'] : path.split('/');

    for (int i = 0; i < pathSegments.length; i++) {
      final segment = pathSegments[i];

      root = _computeNode(
        root,
        segment,
        fullPath: path,
        action: action,
        isLastSegment: i == (pathSegments.length - 1),
      );
    }

    /// parametric nodes being terminal is determined its definitions
    if (root is StaticNode || root is WildcardNode) {
      (root as StaticNode)
        ..addAction(action)
        ..terminal = true;
    }
  }

  RouteResult? lookup(HTTPMethod method, String path, {bool debug = false}) {
    Node rootNode = _root;
    String route = _cleanPath(path);

    Map<String, dynamic> resolvedParams = {};
    List<IndexedHandler> wildcardHandlers = [];

    List<RouteHandler> getResults(List<IndexedHandler> handlers) {
      final resultingHandlers = [
        ...handlers,
        ...wildcardHandlers,
      ]..sort((a, b) => a.index.compareTo(b.index));
      return resultingHandlers.map((e) => e.value).toList();
    }

    final debugLog = StringBuffer("\n");

    void devlog(String message) {
      if (!debug) return;
      debugLog.writeln(message.toLowerCase());
      print(debugLog);
    }

    devlog('Finding node for ---------  ${method.name} $route ------------\n');

    final routeSegments = route == '/' ? ['/'] : route.split('/');

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
        final paramNode = rootNode.paramNode;
        if (paramNode == null) {
          devlog('x Found no static node for part       ->         $routePart');
          devlog('x Route is not registered             ->         $route');

          final wc = rootNode.wildcardNode;
          if (wc == null) return null;

          useWildcard(wc);
          break;
        }

        final hasChild = paramNode.hasChild(routePart);
        if (hasChild) {
          devlog('- Found Static for             ->              $routePart');
          rootNode = paramNode.getChild(routePart);
          continue;
        }

        devlog(
            '- Finding Defn for $routePart        -> terminal?    $isLastPart');

        final paramDefn = paramNode.findMatchingDefinition(
          method,
          routePart,
          shouldBeTerminal: isLastPart,
        );

        devlog('    * parametric defn:         ${paramDefn.toString()}');

        if (paramDefn == null) {
          devlog('x Found no defn for route part      ->         $routePart');
          devlog('x Route is not registered             ->         $route');

          final wc = rootNode.wildcardNode;
          if (wc == null) return null;

          useWildcard(wc);
          break;
        }

        devlog('- Found defn for route part    ->              $routePart');

        final params = paramDefn.resolveParams(currPart);
        resolvedParams.addAll(params);
        rootNode = paramNode;

        if (isLastPart && paramDefn.terminal) {
          rootNode.terminal = true;
          final hdlrs = paramDefn.getActions(method);

          return RouteResult(
            resolvedParams,
            getResults(hdlrs),
            actual: paramDefn,
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
    _printNode(_root, '${_root.name} ');
  }

  void _printNode(Node node, String prefix) {
    if (node.terminal) print('$prefix*');
    node.children.forEach(
      (char, node) => _printNode(node, '$prefix$char -> '),
    );
  }

  String _cleanPath(String path) {
    if (!path.startsWith('/')) {
      throw ArgumentError.value(
          path, null, 'Route registration must start with `/`');
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
}

class RouteResult {
  final Map<String, dynamic> params;
  final List<RouteHandler> handlers;

  @visibleForTesting
  final dynamic actual;

  const RouteResult(
    this.params,
    this.handlers, {
    this.actual,
  });
}
