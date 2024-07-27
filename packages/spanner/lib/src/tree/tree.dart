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

  HandlerStore _on(HTTPMethod method, String path) {
    path = _cleanPath(path);

    Node rootNode = _root;

    if (path == BASE_PATH) {
      return rootNode;
    } else if (path == WildcardNode.key) {
      return rootNode.wildcardNode ??
          rootNode.addChildAndReturn(WildcardNode.key, WildcardNode());
    }

    final pathSegments = path.split('/');

    for (int i = 0; i < pathSegments.length; i += 2) {
      final firstPart = pathSegments[i];
      final secondPart =
          i + 1 < pathSegments.length ? pathSegments[i + 1] : null;
      final thirdPart =
          i + 2 < pathSegments.length ? pathSegments[i + 2] : null;

      final first = Spanner._computeNode(
        rootNode,
        method,
        firstPart,
        config: config,
        fullPath: path,
        nextPart: secondPart,
      );

      /// the only time [result] won't be Node is when we have a parametric definition
      if (first is! Node) return first;

      rootNode = first;

      if (secondPart != null) {
        final second = Spanner._computeNode(
          rootNode,
          method,
          secondPart,
          config: config,
          fullPath: path,
          nextPart: thirdPart,
        );

        if (second is! Node) return second;

        rootNode = second;
      }
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
    String routePart, {
    required RouterConfig config,
    required String? nextPart,
    required String fullPath,
  }) {
    final part = config.caseSensitive ? routePart : routePart.toLowerCase();

    final child = node.maybeChild(part);
    if (child != null) {
      return node.addChildAndReturn(part, child);
    } else if (part.isStatic) {
      return node.addChildAndReturn(part, StaticNode(part));
    } else if (part.isWildCard) {
      if (nextPart != null) {
        throw ArgumentError.value(
          fullPath,
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
    var path = route is Uri ? route.path : route.toString();
    if (path.startsWith(BASE_PATH)) path = path.substring(1);
    if (path.endsWith(BASE_PATH)) path = path.substring(0, path.length - 1);

    final resolvedParams = <ParamAndValue>[];
    final resolvedHandlers = <IndexedValue>[...root.middlewares];

    getResults(IndexedValue? handler) =>
        handler != null ? (resolvedHandlers..add(handler)) : resolvedHandlers;

    Node rootNode = _root;

    if (path.isEmpty) {
      return RouteResult(
        resolvedParams,
        getResults(rootNode.getHandler(method)),
      );
    }

    /// keep track of last wildcard we encounter along route. We'll resort to this
    /// incase we don't find the route we were looking for.
    var wildcardNode = rootNode.wildcardNode;

    final routeSegments = route is Uri ? route.pathSegments : path.split('/');

    for (int i = 0; i < routeSegments.length; i++) {
      final currPart = routeSegments[i];
      final routePart =
          config.caseSensitive ? currPart : currPart.toLowerCase();
      final isLastPart = i == (routeSegments.length - 1);

      final parametricNode = rootNode.paramNode;
      final childNode = rootNode.maybeChild(routePart) ??
          parametricNode?.maybeChild(routePart);

      wildcardNode = childNode?.wildcardNode ?? wildcardNode;

      // set root node as current child
      rootNode = childNode ?? parametricNode ?? rootNode;

      final definition = parametricNode?.findMatchingDefinition(
        method,
        routePart,
        terminal: isLastPart,
        caseSensitive: config.caseSensitive,
        nextPart: isLastPart ? null : routeSegments[i + 1],
      );

      /// If we don't find no matching Static path or a Parametric Node, OR
      /// we don't find a matching path or a matching definition, then
      /// use wildcard if we have any registered
      if ((childNode == null && parametricNode == null) ||
          (childNode == null && definition == null)) {
        if (wildcardNode != null) rootNode = wildcardNode;
        break;
      }

      if (childNode != null) {
        resolvedHandlers.addAll(childNode.middlewares);
        continue;
      }

      definition!.resolveParams(
        currPart,
        resolvedParams,
        caseSentive: config.caseSensitive,
      );

      if (isLastPart && definition.terminal) {
        return RouteResult(
          resolvedParams,
          getResults(definition.getHandler(method)),
          actual: definition,
        );
      }
    }

    if (!rootNode.terminal) {
      return RouteResult(resolvedParams, getResults(null), actual: null);
    }

    final handler = rootNode.getHandler(method);

    return handler == null
        ? null
        : RouteResult(resolvedParams, getResults(handler), actual: rootNode);
  }

  String _cleanPath(String path) {
    if ([BASE_PATH, WildcardNode.key].contains(path)) return path;
    if (!path.startsWith(BASE_PATH)) {
      throw ArgumentError.value(
          path, null, 'Route registration must start with `/`');
    }
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
