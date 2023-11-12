// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:path_to_regexp/path_to_regexp.dart';

import '../middleware/body_parser.dart';
import '../http/response.dart';
import '../http/request.dart';
import '../utils/exceptions.dart';
import 'handler.dart';
import 'route.dart';

const ANY_PATH = '*';

const BASE_PATH = '/';

abstract interface class RouterContract {
  List<Route> get routes;

  void get(String path, RequestHandlerFunc handler);

  void post(String path, RequestHandlerFunc handler);

  void put(String path, RequestHandlerFunc handler);

  void delete(String path, RequestHandlerFunc handler);

  void any(String path, RequestHandlerFunc handler);

  void use(HandlerFunc handler, [Route? route]);

  void group(String prefix, void Function(RouterContract router) groupCtx);
}

abstract class Router implements RouterContract {
  static Router get getInstance => _$PharoahRouter();

  Future<void> handleRequest(HttpRequest request);
}

class _$PharoahRouter extends Router {
  late final RouteGroup _group;
  final Map<String, RouteGroup> _subGroups = {};

  _$PharoahRouter({RouteGroup? group}) {
    if (group == null) {
      _group = RouteGroup(BASE_PATH)..add(bodyParser);
      return;
    }
    _group = group;
  }

  @override
  List<Route> get routes => _group.handlers.map((e) => e.route).toList();

  @override
  void get(String path, RequestHandlerFunc handler) {
    _group.add(RequestHandler(
        handler, Route(path, [HTTPMethod.GET, HTTPMethod.HEAD])));
  }

  @override
  void post(String path, RequestHandlerFunc handler) {
    _group.add(RequestHandler(handler, Route(path, [HTTPMethod.POST])));
  }

  @override
  void put(String path, RequestHandlerFunc handler) {
    _group.add(RequestHandler(handler, Route(path, [HTTPMethod.PUT])));
  }

  @override
  void delete(String path, RequestHandlerFunc handler) {
    _group.add(RequestHandler(handler, Route(path, [HTTPMethod.DELETE])));
  }

  @override
  void any(String path, RequestHandlerFunc handler) {
    _group.add(RequestHandler(handler, Route.any()));
  }

  @override
  void use(HandlerFunc handler, [Route? route]) {
    _group.add(Middleware(handler, route ?? Route.any()));
  }

  @override
  void group(String prefix, Function(RouterContract router) groupCtx) {
    /// do more validation on prefix
    if (prefix == BASE_PATH || prefix == ANY_PATH) {
      throw PharoahException('Prefix :[$prefix] not allowed for groups');
    }
    final router = _$PharoahRouter(group: RouteGroup(prefix));
    groupCtx(router);
    _subGroups[prefix] = router._group;
  }

  @override
  Future<void> handleRequest(HttpRequest httpReq) async {
    final request = Request.from(httpReq);
    final response = Response.from(httpReq, request);

    final handlers = _group.findHandlers(request);
    final group = findRouteGroup(request.path);
    if (group != null) {
      final subHdls = group.findHandlers(request);
      if (subHdls.isNotEmpty) handlers.addAll(subHdls);
    }

    if (hasNoRequestHandlers(handlers)) return response.notFound();

    final handlerFncs = List.from(handlers);
    ReqRes reqRes = (request, response);
    while (handlerFncs.isNotEmpty) {
      final handler = handlerFncs.removeAt(0);
      final completed = handlerFncs.isEmpty;

      try {
        final result = await processHandler(handler, reqRes);
        if (result is Response) break;
        if (result is ReqRes) {
          if (completed) return reqRes.$2.ok();
          reqRes = result;
          continue;
        }
        reqRes.$2.json(result);
      } catch (e) {
        return reqRes.$2.internalServerError();
      }
    }
  }

  Future<dynamic> processHandler(RouteHandler rqh, ReqRes rq) async {
    final result = await rqh.handler(rq.$1, rq.$2);
    if (result != null) return result;
    return rq;
  }

  RouteGroup? findRouteGroup(String path) {
    if (_subGroups.isEmpty) return null;
    final key = _subGroups.keys.firstWhereOrNull(
        (key) => path.contains(key) || pathToRegExp(key).hasMatch(path));
    return key == null ? null : _subGroups[key];
  }

  bool hasNoRequestHandlers(List<RouteHandler> handlers) =>
      !handlers.any((e) => e is RequestHandler);
}
