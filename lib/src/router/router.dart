// ignore_for_file: constant_identifier_names

import 'dart:async';

import '../http/request.dart';
import 'handler.dart';
import 'route.dart';

const ANY_PATH = '*';

const BASE_PATH = '/';

abstract interface class RoutePathDefinitionContract<T> {
  T get(String path, RequestHandlerFunc handler);

  T post(String path, RequestHandlerFunc handler);

  T put(String path, RequestHandlerFunc handler);

  T delete(String path, RequestHandlerFunc handler);

  T use(MiddlewareFunc reqResNext, [Route? route]);
}

mixin RouterMixin<T extends RouteHandler> on RouteHandler
    implements RoutePathDefinitionContract<T> {
  RouteGroup _group = RouteGroup.path(BASE_PATH);

  List<String> get routes =>
      _group.handlers.map((e) => e.route.route!).toList();

  @override
  Route get route => Route(_group.prefix, [HTTPMethod.ALL]);

  @override
  T prefix(String prefix) {
    _group = _group.withPrefix(prefix);
    return this as T;
  }

  @override
  Future<HandlerResult> handle(ReqRes reqRes) {
    next();
    return super.handle(reqRes);
  }

  @override
  T get(String path, RequestHandlerFunc handler) {
    _group.add(RequestHandler(
        handler, Route(path, [HTTPMethod.GET, HTTPMethod.HEAD])));
    return this as T;
  }

  @override
  T post(String path, RequestHandlerFunc handler) {
    _group.add(RequestHandler(handler, Route(path, [HTTPMethod.POST])));
    return this as T;
  }

  @override
  T put(String path, RequestHandlerFunc handler) {
    _group.add(RequestHandler(handler, Route(path, [HTTPMethod.PUT])));
    return this as T;
  }

  @override
  T delete(String path, RequestHandlerFunc handler) {
    _group.add(RequestHandler(handler, Route(path, [HTTPMethod.DELETE])));
    return this as T;
  }

  @override
  T use(MiddlewareFunc reqResNext, [Route? route]) {
    _group.add(Middleware(reqResNext, route ?? Route.any()));
    return this as T;
  }
}

class PharoahRouter extends RouteHandler with RouterMixin<PharoahRouter> {
  @override
  HandlerFunc get handler => (req, res) async {
        return (req: req, res: res);
      };

  @override
  bool get internal => false;
}

class _$PharoahRouter {
  // @override
  // List<Route> get routes => _group.handlers.map((e) => e.route).toList();

  // @override
  // void group(String prefix, Function(RouterContract router) groupCtx) {
  //   if (reservedPaths.contains(prefix)) {
  //     throw PharoahException.value('Prefix not allowed for groups', prefix);
  //   }
  //   final router = _$PharoahRouter(group: RouteGroup(prefix: prefix));
  //   groupCtx(router);
  //   _subGroups[prefix] = router._group;
  // }

  // final key = _routes.keys.firstWhereOrNull(
  //       (key) => path.contains(key) || pathToRegExp(key).hasMatch(path));
  //   return key == null ? null : _routes[key];
}
