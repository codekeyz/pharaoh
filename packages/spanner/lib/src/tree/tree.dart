import 'package:meta/meta.dart';

import 'node.dart';
import '../parametric/definition.dart';
import '../parametric/utils.dart';

// ignore: constant_identifier_names
const BASE_PATH = '/';

typedef RouteEntry = ({HTTPMethod method, String path});

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
    final result = _on(method, path);
    final indexedHandler = (index: _nextIndex, value: handler);

    if (result is ParameterDefinition) {
      result.addRoute(method, indexedHandler);
    } else {
      (result as StaticNode)
        ..addRoute(method, indexedHandler)
        ..terminal = true;
    }

    _currentIndex = _nextIndex;
  }

  void addMiddleware<T>(String path, T handler) {
    final result = _on(HTTPMethod.ALL, path);
    final middleware = (index: _nextIndex, value: handler);

    if (result is Node) {
      result.addMiddleware(middleware);
    } else if (result is ParameterDefinition) {
      result.addMiddleware(middleware);
    }

    _currentIndex = _nextIndex;
  }

  dynamic _on(HTTPMethod method, String path) {
    path = _cleanPath(path);

    Node rootNode = _root;

    if (path == BASE_PATH) {
      return rootNode..terminal = true;
    } else if (path == WildcardNode.key) {
      var wildCardNode = rootNode.wildcardNode;
      if (wildCardNode != null) return wildCardNode..terminal = true;

      wildCardNode = WildcardNode();
      (rootNode as StaticNode).addChildAndReturn(
        WildcardNode.key,
        wildCardNode,
      );
      return wildCardNode..terminal = true;
    }

    final pathSegments = _getRouteSegments(path);
    for (int i = 0; i < pathSegments.length; i++) {
      final segment = pathSegments[i];

      final result = _computeNode(
        rootNode,
        method,
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
    HTTPMethod method,
    String routePart, {
    bool isLastSegment = false,
    required String fullPath,
  }) {
    String part = routePart;
    if (!config.caseSensitive) part = part.toLowerCase();

    final key = _getNodeKey(part);
    final child = node.maybeChild(part);

    if (child != null) {
      return node.addChildAndReturn(key, child);
    }

    if (part.isStatic) {
      return node.addChildAndReturn(key, StaticNode(key));
    }

    if (part.isWildCard) {
      if (!isLastSegment) {
        throw ArgumentError.value(
          fullPath,
          null,
          'Route definition is not valid. Wildcard must be the end of the route',
        );
      }
      return node.addChildAndReturn(key, WildcardNode());
    }

    final defn = buildParamDefinition(routePart, isLastSegment);
    final paramNode = node.paramNode;

    if (paramNode == null) {
      final newNode = node.addChildAndReturn(key, ParametricNode(method, defn));
      return isLastSegment ? defn : newNode;
    }

    paramNode.addNewDefinition(method, defn);
    return isLastSegment ? defn : node.addChildAndReturn(key, paramNode);
  }

  RouteResult? lookup(
    HTTPMethod method,
    dynamic route, {
    void Function(String)? devlog,
  }) {
    var path = route is Uri ? route.path : route.toString();
    if (path.startsWith(BASE_PATH)) path = path.substring(1);
    if (path.endsWith(BASE_PATH)) path = path.substring(0, path.length - 1);

    var routeSegments = route is Uri ? route.pathSegments : path.split('/');

    final resolvedParams = <String, dynamic>{};
    final resolvedHandlers = <IndexedValue>[];

    void insertHandler(IndexedValue handler) {
      int index = resolvedHandlers.indexWhere((h) => h.index > handler.index);
      if (index == -1) {
        resolvedHandlers.add(handler);
      } else {
        resolvedHandlers.insert(index, handler);
      }
    }

    void collectMiddlewares(Node node) {
      for (final middleware in node.middlewares) {
        insertHandler(middleware);
      }
    }

    List<dynamic> getResults(IndexedValue? handler) => ([
          ...resolvedHandlers,
          if (handler != null) handler,
        ]).map((e) => e.value).toList(growable: false);

    Node rootNode = _root;

    /// keep track of last wildcard we encounter along route. We'll resort to this
    /// incase we don't find the route we were looking for.
    WildcardNode? wildcardNode = rootNode.wildcardNode;

    collectMiddlewares(rootNode);

    if (path == BASE_PATH) {
      return RouteResult(
        resolvedParams,
        getResults(rootNode.getHandler(method)),
      );
    }

    devlog?.call(
      'Finding node for ---------  ${method.name} $path ------------\n',
    );

    for (int i = 0; i < routeSegments.length; i++) {
      final String currPart = routeSegments[i];
      final routePart =
          config.caseSensitive ? currPart : currPart.toLowerCase();
      final isLastPart = i == (routeSegments.length - 1);

      void useWildcard(WildcardNode wildcard) {
        resolvedParams['*'] = routeSegments.sublist(i).join('/');
        rootNode = wildcard;
      }

      if (rootNode.hasChild(routePart)) {
        rootNode = rootNode.getChild(routePart);
        collectMiddlewares(rootNode);

        final wcNode = rootNode.wildcardNode;
        if (wcNode != null) wildcardNode = wcNode;

        devlog?.call('- Found Static for                ->         $routePart');
      } else {
        final parametricNode = rootNode.paramNode;
        if (parametricNode == null) {
          devlog?.call(
            'x Found no Static Node for part   ->         $routePart',
          );
          devlog?.call('x Route is not found              ->         $path');

          if (wildcardNode != null) {
            useWildcard(wildcardNode);
            break;
          }

          return RouteResult(resolvedParams, getResults(null), actual: null);
        }

        if (parametricNode.hasChild(routePart)) {
          devlog?.call(
            '- Found Static for             ->              $routePart',
          );
          rootNode = parametricNode.getChild(routePart);
          final wcNode = rootNode.wildcardNode;
          if (wcNode != null) wildcardNode = wcNode;
          continue;
        }

        devlog?.call(
          '- Finding Defn for $routePart        -> terminal?    $isLastPart',
        );

        final definition = parametricNode.findMatchingDefinition(
          method,
          routePart,
          terminal: isLastPart,
        );

        devlog?.call('    * parametric defn:         ${definition.toString()}');

        if (definition == null) {
          if (wildcardNode != null) {
            useWildcard(wildcardNode);
            break;
          }

          if (parametricNode.definitions.length == 1) {
            final definition = parametricNode.definitions.first;
            if (definition is CompositeParameterDefinition) break;

            /// if we have more path segments, do not pass it as a parameteric value
            final partsLeft = routeSegments.sublist(i);
            if (partsLeft.length > 1) break;

            final name = parametricNode.definitions.first.name;
            resolvedParams[name] = partsLeft.join('/');

            return RouteResult(
              resolvedParams,
              getResults(definition.getHandler(method)),
              actual: definition,
            );
          }
          break;
        }

        devlog?.call(
          '- Found defn for route part    ->              $routePart',
        );

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

  List<String> _getRouteSegments(String route) => route.split('/');

  String _getNodeKey(String part) =>
      part.isParametric ? ParametricNode.key : part;
}

class RouteResult {
  final Map<String, dynamic> params;
  final List<dynamic> values;

  /// this is either a Node or Parametric Definition
  @visibleForTesting
  final dynamic actual;

  const RouteResult(this.params, this.values, {this.actual});
}
