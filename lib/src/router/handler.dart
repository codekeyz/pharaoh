import 'dart:async';

import '../http/request.dart';
import '../http/response.dart';
import '../utils/exceptions.dart';
import 'route.dart';

typedef ReqRes = ({Request req, Response res});

/// This type of handler allows you to use the actual
/// request instance [Request].
///
/// This way you can reprocess contents in the
/// request before it reaches other handlers in your application.
///
/// See here: [Middleware]
typedef HandlerFunc = FutureOr<dynamic> Function(Request req, Response res);

typedef HandlerResult = ({bool canNext, ReqRes reqRes});

/// All route handler types must extend this class.
///
/// See: [RequestHandler] and [Middleware] types
abstract class RouteHandler<T> {
  Route get route;
  T get handler;

  Map<String, String> _routeParams = {};

  Map<String, String> get params => _routeParams;

  bool _canNext = false;

  bool get canNext => _canNext;

  void next() => _canNext = true;

  void setParams(Map<String, String> params) {
    _routeParams = params;
  }

  RouteHandler prefix(String prefix);

  Future<HandlerResult> handle(final ReqRes reqRes) async {
    final req = reqRes.req;
    if (_routeParams.isNotEmpty) {
      for (final param in params.entries) {
        req.updateParams(param.key, param.value);
      }
    }

    final r = await (handler as dynamic)(req, reqRes.res);
    return switch (r.runtimeType) {
      // ignore: prefer_void_to_null
      Null => (canNext: true, reqRes: reqRes),
      Response => (canNext: true, reqRes: (req: req, res: (r as Response))),
      Type() =>
        throw PharoahException.value("Unknown result type from handler", r),
    };
  }
}

typedef RequestHandlerFunc = FutureOr<dynamic> Function(
  $Request req,
  $Response res,
);

class RequestHandler extends RouteHandler<RequestHandlerFunc> {
  final RequestHandlerFunc _func;
  final Route _route;

  RequestHandler(this._func, this._route);

  @override
  RequestHandler prefix(String prefix) => RequestHandler(
        _func,
        route.withPrefix(prefix),
      );

  @override
  RequestHandlerFunc get handler => _func;

  @override
  Route get route => _route;

  @override
  Future<HandlerResult> handle(ReqRes reqRes) {
    next();
    return super.handle(reqRes);
  }
}

///  [Middleware] type route handler
///
///
///
///
///  The foremost thing you should know is 'middl'
typedef MiddlewareFunc = Function(Request req, Response res, Function next);

class Middleware extends RouteHandler<HandlerFunc> {
  final MiddlewareFunc _func;
  final Route _route;
  Middleware(this._func, this._route);

  @override
  Middleware prefix(String prefix) => Middleware(
        _func,
        route.withPrefix(prefix),
      );

  @override
  HandlerFunc get handler => (req, res) => _func(
        req,
        res,
        () => next(),
      );

  @override
  Route get route => _route;
}
