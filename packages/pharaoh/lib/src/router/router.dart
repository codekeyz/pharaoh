import 'dart:async';

import '../http/request.dart';
import 'handler.dart';
import 'route.dart';

const basePath = '/';

abstract interface class RoutePathDefinitionContract<T> {
  T get(String path, RequestHandlerFunc handler);

  T post(String path, RequestHandlerFunc handler);

  T put(String path, RequestHandlerFunc handler);

  T delete(String path, RequestHandlerFunc handler);

  T head(String path, RequestHandlerFunc handler);

  T patch(String path, RequestHandlerFunc handler);

  T options(String path, RequestHandlerFunc handler);

  T trace(String path, RequestHandlerFunc handler);

  T use(HandlerFunc reqResNext, [Route? route]);
}

mixin RouterMixin<T extends RouteHandler> on RouteHandler
    implements RoutePathDefinitionContract<T> {
  RouteGroup _group = RouteGroup.path(basePath);

  List<Route> get routes => _group.handlers.map((e) => e.route).toList();

  @override
  Route get route => Route(_group.prefix, [HTTPMethod.ALL]);

  @override
  T prefix(String prefix) {
    _group = _group.withPrefix(prefix);
    return this as T;
  }

  @override
  Future<HandlerResult> handle(ReqRes reqRes) async {
    final handlers = _group.findHandlers(reqRes.req);
    if (handlers.isEmpty) {
      return (
        canNext: true,
        reqRes: (req: reqRes.req, res: reqRes.res.notFound())
      );
    }

    final handlerFncs = List<RouteHandler>.from(handlers);

    ReqRes result = reqRes;
    bool canNext = false;

    while (handlerFncs.isNotEmpty) {
      canNext = false;
      final handler = handlerFncs.removeAt(0);
      final data = await handler.handle(reqRes);
      result = data.reqRes;
      canNext = data.canNext;

      final breakOut = result.res.ended || !canNext;
      if (breakOut) break;
    }

    result = await _postHandlerJob(result);

    return (canNext: canNext, reqRes: result);
  }

  Future<ReqRes> _postHandlerJob(ReqRes reqRes) async {
    var req = reqRes.req, res = reqRes.res;

    /// deal with sessions
    final session = req.session;
    if (session != null &&
        (session.saveUninitialized || session.resave || session.modified)) {
      await session.save();
      res = res.withCookie(session.cookie!);
    }

    return (req: req, res: res);
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
  T head(String path, RequestHandlerFunc handler) {
    _group.add(RequestHandler(handler, Route(path, [HTTPMethod.HEAD])));
    return this as T;
  }

  @override
  T patch(String path, RequestHandlerFunc handler) {
    _group.add(RequestHandler(handler, Route(path, [HTTPMethod.PATCH])));
    return this as T;
  }

  @override
  T options(String path, RequestHandlerFunc handler) {
    _group.add(RequestHandler(handler, Route(path, [HTTPMethod.OPTIONS])));
    return this as T;
  }

  @override
  T trace(String path, RequestHandlerFunc handler) {
    _group.add(RequestHandler(handler, Route(path, [HTTPMethod.TRACE])));
    return this as T;
  }

  @override
  T use(HandlerFunc reqResNext, [Route? route]) {
    _group.add(Middleware(reqResNext, route ?? Route.any()));
    return this as T;
  }
}

class PharaohRouter extends RouteHandler with RouterMixin<PharaohRouter> {
  @override
  HandlerFunc get handler => (req, res, next) => (req: req, res: res, next);
}
