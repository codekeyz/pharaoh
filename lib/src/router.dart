// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:io';

import 'response.dart';
import 'utils.dart';

const ANY_PATH = '*';

const BASE_PATH = '/';

enum HTTPMethod { GET, HEAD, POST, PUT, DELETE, ALL }

typedef ReqRes = (HttpRequest req, Response res);

typedef HandlerFunc = FutureOr<dynamic> Function(HttpRequest req, Response res);

typedef ProcessHandlerFunc = (ReqRes data, HandlerFunc handler);

class Route {
  final String route;
  final List<HTTPMethod> verbs;
  const Route(this.route, this.verbs);

  /// any routes with the following [HTTPMethod]
  Route.all([HTTPMethod method = HTTPMethod.ALL])
      : verbs = [method],
        route = ANY_PATH;

  /// any route or any method
  Route.any()
      : verbs = [],
        route = ANY_PATH;

  bool match(HTTPMethod method, String path) {
    final anyMethod = verbs.isEmpty;
    if (!anyMethod) {
      final canMethod = verbs[0] == HTTPMethod.ALL || verbs.contains(method);
      if (!canMethod) return false;
    }

    if (route == ANY_PATH) return true;

    // TODO: extend path matching to support complex types
    return route == path;
  }
}

class RouteGroup {
  String prefix;
  List<RequestHandler> routes;

  RouteGroup._(this.prefix) : routes = [];

  void add(RequestHandler handler) {
    /// TODO: do checks here to make sure there's
    /// no duplicate entry in the routes
    routes.add(handler);
  }

  List<RequestHandler> _findHandlers(HTTPMethod method, String path) {
    return routes.where((e) => e.route.match(method, path)).toList();
  }
}

enum RequestHandlerType {
  middleware,
  endpoints,
}

class RequestHandler {
  final Route route;
  final HandlerFunc handler;
  const RequestHandler(this.handler, this.route);
  RequestHandlerType get type => RequestHandlerType.endpoints;
}

class Middleware extends RequestHandler {
  Middleware(super.handler, super.route);
  @override
  RequestHandlerType get type => RequestHandlerType.middleware;
}

mixin RouterContract {
  List<RequestHandler> get routes;

  void get(String path, HandlerFunc handler);

  void post(String path, HandlerFunc handler);

  void put(String path, HandlerFunc handler);

  void delete(String path, HandlerFunc handler);

  void any(String path, HandlerFunc handler);

  void use(HandlerFunc handler);

  RouteGroup group(String prefix, void Function(PharoahRouter router) groupCtx);
}

abstract class Router with RouterContract {
  static Router get getInstance => PharoahRouter();

  Future<void> handleRequest(HttpRequest request);

  FutureOr<Router> commit();
}

class PharoahRouter extends Router {
  late final RouteGroup _group;

  String get prefix => _group.prefix;

  final Map<String, RouteGroup> _subGroups = {};

  PharoahRouter({RouteGroup? group})
      : _group = group ?? RouteGroup._(BASE_PATH);

  @override
  List<RequestHandler> get routes => _group.routes;

  @override
  void get(String path, HandlerFunc handler) {
    _group.add(RequestHandler(
      handler,
      Route(path, [HTTPMethod.GET, HTTPMethod.HEAD]),
    ));
  }

  @override
  void post(String path, HandlerFunc handler) {
    _group.add(RequestHandler(
      handler,
      Route(path, [HTTPMethod.POST]),
    ));
  }

  @override
  void put(String path, HandlerFunc handler) {
    _group.add(RequestHandler(
      handler,
      Route(path, [HTTPMethod.PUT]),
    ));
  }

  @override
  void delete(String path, HandlerFunc handler) {
    _group.add(RequestHandler(
      handler,
      Route(path, [HTTPMethod.DELETE]),
    ));
  }

  @override
  void any(String path, HandlerFunc handler) {
    _group.add(RequestHandler(handler, Route.any()));
  }

  @override
  Future<void> handleRequest(HttpRequest request) async {
    final method = getHttpMethod(request);
    final path = request.uri.toString();
    final response = Response.from(request);

    final handlers = _group._findHandlers(method, path);
    if (handlers.isEmpty) {
      return await response.status(HttpStatus.notFound).json({
        "message": "No handler found for path :$path",
        "path": path,
      });
    }

    final handlerFncs = List.from(handlers);

    ReqRes reqRes = (request, response);
    while (handlerFncs.isNotEmpty) {
      final handler = handlerFncs.removeAt(0);
      final result = await processHandler(handler, reqRes);
      if (result is ReqRes) {
        reqRes = result;
        continue;
      }
      if (result is HttpResponse) break;
      await reqRes.$2.json(result);
      break;
    }
  }

  Future<dynamic> processHandler(RequestHandler rqh, ReqRes rq) async {
    try {
      final result = await rqh.handler(rq.$1, rq.$2);
      if (result != null) return result;
      return rq;
    } catch (e) {
      return await rq.$2
          .status(HttpStatus.internalServerError)
          .json({"message": "An error occurred"});
    }
  }

  @override
  void use(HandlerFunc handler) {
    _group.add(Middleware(handler, Route.all()));
  }

  @override
  FutureOr<Router> commit() async {
    return this;
  }

  @override
  RouteGroup group(String prefix, Function(PharoahRouter router) groupCtx) {
    /// do more validation on prefix
    if (prefix == BASE_PATH || prefix == ANY_PATH) {
      throw Exception('Group Prefix not allowed prefix: $prefix');
    }

    final router = PharoahRouter(group: RouteGroup._(prefix));
    groupCtx(router);

    final group = router._group;
    _subGroups[prefix] = group;
    return group;
  }
}
