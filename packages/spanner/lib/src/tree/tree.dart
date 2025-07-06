import 'package:meta/meta.dart';

import 'node.dart';
import '../parametric/definition.dart';
import '../parametric/utils.dart';

// ignore: constant_identifier_names
const BASE_PATH = '/';

// ignore: constant_identifier_names
enum HTTPMethod { GET, HEAD, POST, PUT, DELETE, ALL, PATCH, OPTIONS, TRACE }

class RouterConfig {
  final bool caseSensitive;
  final bool ignoreTrailingSlash;

  const RouterConfig({
    this.caseSensitive = true,
    this.ignoreTrailingSlash = true,
  });
}

class Spanner {
  final RouterConfig config;
  late final Node _root;

  Node get root => _root;

  int _currentIndex = 0;

  int get _nextIndex => _currentIndex + 1;

  Spanner({this.config = const RouterConfig()}) : _root = StaticNode(BASE_PATH);

  void addRoute<T>(HTTPMethod method, String path, T handler) {
    _on(method, path).addRoute(method, (
      index: _nextIndex,
      value: handler,
    ));

    _currentIndex = _nextIndex;
  }

  void addMiddleware<T>(String path, T handler) {
    _on(HTTPMethod.ALL, path).addMiddleware((
      index: _nextIndex,
      value: handler,
    ));

    _currentIndex = _nextIndex;
  }

  void attachNode(String path, Node node) {
    final pathSegments = getRoutePathSegments(path);
    if (pathSegments.isEmpty) {
      root.addChildAndReturn(BASE_PATH, node);
    }

    Node rootNode = root;

    final totalLength = pathSegments.length;
    for (int i = 0; i < totalLength; i++) {
      final routePart = pathSegments[i];
      final isLastPart = i == totalLength - 1;

      final maybeChild = rootNode.maybeChild(routePart);
      if (isLastPart) {
        if (maybeChild != null) {
          throw ArgumentError.value(path, null, 'Route entry already exists');
        }

        rootNode = rootNode.addChildAndReturn(
          routePart,
          node..offsetIndex(_currentIndex),
        );

        _currentIndex = _nextIndex;
        break;
      }

      if (maybeChild == null) {
        rootNode = rootNode.addChildAndReturn(routePart, StaticNode(routePart));
      }
    }
  }

  HandlerStore _on(HTTPMethod method, String path) {
    final parts = getRoutePathSegments(path);
    Node rootNode = _root;

    if (parts.isEmpty) {
      return rootNode;
    }

    if (parts[0] == WildcardNode.key) {
      return rootNode.wildcardNode ??
          rootNode.addChildAndReturn(WildcardNode.key, WildcardNode());
    }

    for (int index = 0; index < parts.length; index++) {
      final result = Spanner._computeNode(
        rootNode,
        method,
        index,
        parts: parts,
        config: config,
      );

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
  static HandlerStore _computeNode(
    Node node,
    HTTPMethod method,
    int index, {
    required List<String> parts,
    required RouterConfig config,
  }) {
    final routePart = parts[index];
    final nextPart = parts.elementAtOrNull(index + 1);
    final part = config.caseSensitive ? routePart : routePart.toLowerCase();
    final child = node.maybeChild(part);
    if (child != null) {
      return node.addChildAndReturn(part, child);
    } else if (part.isStatic) {
      return node.addChildAndReturn(part, StaticNode(part));
    } else if (part.isWildCard) {
      if (nextPart != null) {
        throw ArgumentError.value(
          parts.join('/'),
          null,
          'Route definition is not valid. Wildcard must be the end of the route',
        );
      }
      return node.addChildAndReturn(WildcardNode.key, WildcardNode());
    }

    final defn = buildParamDefinition(routePart);
    final paramNode = node.paramNode;

    if (paramNode == null) {
      final newNode = node.addChildAndReturn(
        ParametricNode.key,
        ParametricNode(method, defn),
      );
      return nextPart == null ? defn : newNode;
    }

    paramNode.addNewDefinition(method, defn, nextPart == null);

    return nextPart == null
        ? defn
        : node.addChildAndReturn(ParametricNode.key, paramNode);
  }

  RouteResult? lookup(HTTPMethod method, dynamic route) {
    final pathSegments = getRoutePathSegments(route);

    final resolvedParams = <ParamAndValue>[];
    final resolvedHandlers = <IndexedValue>[...root.middlewares];

    @pragma('vm:prefer-inline')
    getResults(IndexedValue? handler) =>
        handler != null ? (resolvedHandlers..add(handler)) : resolvedHandlers;

    if (pathSegments.isEmpty) {
      return RouteResult(
        resolvedParams,
        getResults(_root.getHandler(method)),
      );
    }

    Node rootNode = _root;

    /// keep track of last wildcard we encounter along route. We'll resort to this
    /// incase we don't find the route we were looking for.
    var wildcardNode = rootNode.wildcardNode;

    for (int i = 0; i < pathSegments.length; i++) {
      final currPart = pathSegments[i];
      final routePart =
          config.caseSensitive ? currPart : currPart.toLowerCase();
      final isLastPart = i == (pathSegments.length - 1);

      final parametricNode = rootNode.paramNode;
      final childNode = rootNode.maybeChild(routePart) ??
          parametricNode?.maybeChild(routePart);

      if (childNode is StaticNode && isLastPart) {
        rootNode = childNode;
        break;
      }

      wildcardNode = childNode?.wildcardNode ?? wildcardNode;

      if (childNode == null && parametricNode == null) {
        if (wildcardNode == null) {
          return RouteResult(resolvedParams, getResults(null));
        }

        rootNode = wildcardNode;
        break;
      }

      rootNode = (childNode ?? parametricNode)!;

      final definition = parametricNode?.findMatchingDefinition(
        method,
        routePart,
        terminal: isLastPart,
      );

      /// If we don't find a matching path or a matching definition, then
      /// use wildcard if we have any registered
      if (childNode == null && definition == null) {
        if (wildcardNode != null) rootNode = wildcardNode;
        break;
      }

      if (childNode != null) {
        resolvedHandlers.addAll(childNode.middlewares);
        continue;
      }

      definition!.resolveParams(currPart, resolvedParams);

      if (isLastPart && definition.terminal) {
        return RouteResult(
          resolvedParams,
          getResults(definition.getHandler(method)),
          actual: definition,
        );
      }
    }

    resolvedHandlers.addAll(rootNode.middlewares);

    return !rootNode.terminal
        ? RouteResult(resolvedParams, getResults(null), actual: null)
        : RouteResult(
            resolvedParams,
            getResults(rootNode.getHandler(method)),
            actual: rootNode,
          );
  }

  List<String> getRoutePathSegments(dynamic route) {
    if (route is Uri) return route.pathSegments;
    if (route == BASE_PATH) return const [];
    if (route == WildcardNode.key) return const [WildcardNode.key];

    var path = route.toString();
    if (path.isEmpty) return const [];

    if (path.startsWith(BASE_PATH)) path = path.substring(1);
    if (path.endsWith(BASE_PATH)) path = path.substring(0, path.length - 1);
    return path.split('/');
  }
}

class RouteResult {
  final List<ParamAndValue> _params;
  final List<IndexedValue> _values;

  /// this is either a Node or Parametric Definition
  @visibleForTesting
  final dynamic actual;

  RouteResult(this._params, this._values, {this.actual});

  Iterable<dynamic>? _cachedValues;
  Iterable<dynamic> get values {
    if (_cachedValues != null) return _cachedValues!;
    _values.sort((a, b) => a.index.compareTo(b.index));
    return _cachedValues = _values.map((e) => e.value);
  }

  Map<String, dynamic>? _cachedParams;
  Map<String, dynamic> get params {
    if (_cachedParams != null) return _cachedParams!;
    return {for (final entry in _params) entry.name: entry.value};
  }
}
