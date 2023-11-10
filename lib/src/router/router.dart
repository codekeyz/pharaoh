// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:io';
import 'package:path_to_regexp/path_to_regexp.dart';

import '../response.dart';
import 'route.dart';
import '../utils.dart';

const ANY_PATH = '*';

const BASE_PATH = '/';

enum HTTPMethod { GET, HEAD, POST, PUT, DELETE, ALL }

typedef ReqRes = (HttpRequest req, Response res);

typedef ProcessHandlerFunc = (ReqRes data, HandlerFunc handler);

typedef HandlerFunc = FutureOr<dynamic> Function(HttpRequest req, Response res);

abstract interface class RouterContract {
  List<Route> get routes;

  void get(String path, HandlerFunc handler);

  void post(String path, HandlerFunc handler);

  void put(String path, HandlerFunc handler);

  void delete(String path, HandlerFunc handler);

  void any(String path, HandlerFunc handler);

  void use(HandlerFunc handler);

  void group(
    String prefix,
    void Function(RouterContract router) groupCtx,
  );
}

abstract class Router implements RouterContract {
  static Router get getInstance => _$PharoahRouter();

  Future<void> handleRequest(HttpRequest request);

  FutureOr<Router> commit();
}

class _$PharoahRouter extends Router {
  late final RouteGroup _group;

  String get prefix => _group.prefix;

  final Map<String, RouteGroup> _subGroups = {};

  _$PharoahRouter({RouteGroup? group})
      : _group = group ?? RouteGroup(BASE_PATH);

  @override
  List<Route> get routes => _group.handlers.map((e) => e.route).toList();

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

    final handlers = _group.findHandlers(method, path);
    if (hasNoRequestHandlers(handlers)) {
      final group = findRouteGroup(path);
      if (group != null) {
        final subHdls = group.findHandlers(method, path);
        if (subHdls.isNotEmpty) handlers.addAll(subHdls);
      }

      if (hasNoRequestHandlers(handlers)) {
        return await response.status(HttpStatus.notFound).json({
          "message": "No handler found for path :$path",
          "path": path,
        });
      }
    }

    final handlerFncs = List.from(handlers);
    ReqRes reqRes = (request, response);
    while (handlerFncs.isNotEmpty) {
      final handler = handlerFncs.removeAt(0);
      final completed = handlerFncs.isEmpty;
      final result = await processHandler(handler, reqRes);
      if (result is HttpResponse) break;
      if (result is ReqRes) {
        if (completed) {
          reqRes.$2.ok();
          break;
        }
        reqRes = result;
        continue;
      }
      reqRes.$2.json(result);
      break;
    }
  }

  Future<dynamic> processHandler(RouteHandler rqh, ReqRes rq) async {
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
  void group(String prefix, Function(RouterContract router) groupCtx) {
    /// do more validation on prefix
    if (prefix == BASE_PATH || prefix == ANY_PATH) {
      throw Exception('Group Prefix not allowed prefix: $prefix');
    }
    final router = _$PharoahRouter(group: RouteGroup(prefix));
    groupCtx(router);
    _subGroups[prefix] = router._group;
  }

  RouteGroup? findRouteGroup(String path) {
    for (final key in _subGroups.keys) {
      bool isMatch = path.contains(key);
      if (!isMatch) isMatch = pathToRegExp(key).hasMatch(path);
      if (isMatch) return _subGroups[key];
    }
    return null;
  }

  bool hasNoRequestHandlers(List<RouteHandler> handlers) =>
      !handlers.any((e) => e is RequestHandler);
}
