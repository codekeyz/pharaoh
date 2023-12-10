import 'package:meta/meta.dart';

import 'node.dart';
import '../route/action.dart';
import '../parametric/definition.dart';
import '../parametric/utils.dart';

// ignore: constant_identifier_names
const BASE_PATH = '/';

// ignore: constant_identifier_names
enum HTTPMethod { GET, HEAD, POST, PUT, DELETE, ALL, PATCH, OPTIONS, TRACE }

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

  List<RouteEntry> get routes => _getRoutes(_root);

  String get routeStr => routes.map((e) => '${e.method.name} ${e.path}').join('\n');

  void addRoute<T>(HTTPMethod method, String path, T handler) {
    final indexedHandler = (index: _nextIndex, value: handler);

    dynamic result = _on(path);

    /// parametric nodes being terminal is determined its definitions
    if (result is StaticNode || result is WildcardNode) {
      (result as StaticNode)
        ..addRoute(method, indexedHandler)
        ..terminal = true;
    } else if (result is ParameterDefinition) {
      result.addRoute(method, indexedHandler);
    }

    _currentIndex = _nextIndex;
  }

  void addMiddleware<T>(String path, T handler) {
    final middleware = (index: _nextIndex, value: handler);

    dynamic result = _on(path);

    if (result is Node) {
      result.addMiddleware(middleware);
    } else if (result is ParameterDefinition) {
      result.addMiddleware(middleware);
    }

    _currentIndex = _nextIndex;
  }

  dynamic _on(String path) {
    path = _cleanPath(path);

    Node rootNode = _root;

    if (path == BASE_PATH) {
      return rootNode..terminal = true;
    } else if (path == WildcardNode.key) {
      var wildCardNode = rootNode.wildcardNode;
      if (wildCardNode != null) return wildCardNode..terminal = true;

      wildCardNode = WildcardNode();
      (rootNode as StaticNode).addChildAndReturn(WildcardNode.key, wildCardNode);
      return wildCardNode..terminal = true;
    }

    final pathSegments = _getRouteSegments(path);
    for (int i = 0; i < pathSegments.length; i++) {
      final segment = pathSegments[i];

      final result = _computeNode(
        rootNode,
        segment,
        fullPath: path,
        isLastSegment: i == (pathSegments.length - 1),
      );

      /// the only time [result] won't be Node is when we have a parametric definition
      /// that is a terminal. It's safe to break the loop since we're already
      /// on the last segment anyways.
      if (result is! Node) return result;

      rootNode = result;
    }

    return rootNode;
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
  /// we will find a static child `users` or create one, then proceed to search
  /// for a [ParametricNode] on the current root [node]. If found, we fill add a new
  /// definition, or create a new [ParametricNode] with this definition.
  dynamic _computeNode(
    Node node,
    String routePart, {
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
        final newNode = node.addChildAndReturn(key, ParametricNode(defn));
        if (isLastSegment) return defn;

        return newNode;
      }

      final defn = ParameterDefinition.from(routePart, terminal: isLastSegment);
      paramNode.addNewDefinition(defn);
      if (isLastSegment) return defn;

      return node.addChildAndReturn(key, paramNode);
    }
  }

  RouteResult? lookup(HTTPMethod method, String path, {bool debug = false}) {
    Node rootNode = _root;

    Map<String, dynamic> resolvedParams = {};
    List<IndexedValue> resolvedHandlers = [...rootNode.middlewares];

    List<dynamic> getResults(IndexedValue? handler) {
      final resultingHandlers = [
        if (handler != null) handler,
        ...resolvedHandlers,
      ]..sort((a, b) => a.index.compareTo(b.index));

      return resultingHandlers.map((e) => e.value).toList();
    }

    if (path == BASE_PATH) {
      rootNode as StaticNode;
      return RouteResult(resolvedParams, getResults(rootNode.getHandler(method)));
    }

    final debugLog = StringBuffer("\n");

    void devlog(String message) {
      if (!debug) return;
      debugLog.writeln(message);
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

      void useWildcard(WildcardNode wildcard) {
        resolvedParams['*'] = routeSegments.sublist(i).join('/');
        rootNode = wildcard;
      }

      void extractNodeMdws(StaticNode node) {
        final mdws = node.middlewares;
        if (mdws.isEmpty) return;
        resolvedHandlers.addAll(mdws);
      }

      if (hasChild) {
        rootNode = rootNode.getChild(routePart);
        extractNodeMdws(rootNode as StaticNode);
        devlog('- Found Static for             ->              $routePart');
      } else {
        final parametricNode = rootNode.paramNode;
        if (parametricNode == null) {
          devlog('x Found no static node for part       ->         $routePart');
          devlog('x Route is not registered             ->         $route');

          final wc = rootNode.wildcardNode;
          if (wc == null) {
            return RouteResult(resolvedParams, getResults(null), actual: null);
          }

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
          terminal: isLastPart,
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

            return RouteResult(
              resolvedParams,
              getResults(definition.getHandler(method)),
              actual: definition,
            );
          }
          break;
        }

        devlog('- Found defn for route part    ->              $routePart');

        final params = definition.resolveParams(currPart);
        resolvedParams.addAll(params);
        rootNode = parametricNode;

        if (isLastPart && definition.terminal) {
          return RouteResult(
            resolvedParams,
            getResults(definition.getHandler(method)),
            actual: definition,
          );
        }
      }
    }

    if (debug) {
      print(debugLog);
    }

    if (!rootNode.terminal) {
      return RouteResult(resolvedParams, getResults(null), actual: null);
    }

    final handler = rootNode.getHandler(method);
    if (handler == null) return null;

    return RouteResult(resolvedParams, getResults(handler), actual: rootNode);
  }

  void printTree() {
    print(routeStr);
  }

  String _cleanPath(String path) {
    if ([BASE_PATH, WildcardNode.key].contains(path)) return path;
    if (!path.startsWith(BASE_PATH)) {
      throw ArgumentError.value(path, null, 'Route registration must start with `/`');
    }
    if (config.ignoreDuplicateSlashes) {
      path = path.replaceAll(RegExp(r'/+'), '/');
    }
    if (config.ignoreTrailingSlash) {
      path = path.replaceAll(RegExp(r'/+$'), '');
    }
    return path.substring(1);
  }

  List<String> _getRouteSegments(String route) => route.split('/');

  String _getNodeKey(String part) => part.isParametric ? ParametricNode.key : part;
}

class RouteResult {
  final Map<String, dynamic> params;
  final List<dynamic> values;

  @visibleForTesting
  final dynamic actual;

  const RouteResult(
    this.params,
    this.values, {
    this.actual,
  });
}

List<RouteEntry> _getRoutes(Node node) {
  final routes = <RouteEntry>[];

  void iterateNode(Node node, String prefix) {
    final hasTerminalInParametricNode = node is ParametricNode && node.hasTerminal;
    if (node.terminal || hasTerminalInParametricNode) {
      final entries = _getNodeEntries(node, prefix);
      routes.addAll(entries);
    }

    node.children.forEach((char, node) {
      String path = '$prefix$char';
      if (node.hasChildren) path += ' / ';

      return iterateNode(node, path);
    });
  }

  iterateNode(node, '/ ');

  return routes;
}

typedef RouteEntry = ({HTTPMethod method, String path});

Iterable<RouteEntry> _getNodeEntries(Node node, String prefix) {
  switch (node.runtimeType) {
    case StaticNode:
    case WildcardNode:
      final methods = (node as StaticNode).methods;
      return methods.map<RouteEntry>((e) => (method: e, path: prefix));
    case ParametricNode:
      final definitions = (node as ParametricNode).definitions.where((e) => e.terminal);
      final entries = <RouteEntry>[];
      for (final defn in definitions) {
        final result = defn.methods.map<RouteEntry>((e) => (method: e, path: prefix));
        entries.addAll(result);
      }
      return entries;
  }

  return [];
}
