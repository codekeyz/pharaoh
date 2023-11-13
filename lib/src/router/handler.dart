import 'dart:async';

import '../http/request.dart';
import '../http/response.dart';
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
  bool get internal;

  bool _canNext = false;

  bool get canNext => _canNext;

  void next() => _canNext = true;

  RouteHandler prefix(String prefix);

  Future<HandlerResult> handle(ReqRes reqRes) async {
    final hdlrResult = await (handler as dynamic)(reqRes.req, reqRes.res);
    if (hdlrResult is ReqRes) {
      return (
        canNext: canNext,
        reqRes: hdlrResult,
      );
    } else if (hdlrResult is Request) {
      return (
        canNext: canNext,
        reqRes: (req: hdlrResult, res: reqRes.res),
      );
    } else if (hdlrResult is Response) {
      return (
        canNext: canNext,
        reqRes: (req: reqRes.req, res: hdlrResult),
      );
    } else if (hdlrResult == null) {
      return (
        canNext: canNext,
        reqRes: reqRes,
      );
    } else if (hdlrResult is Map || hdlrResult is List) {
      return (
        canNext: canNext,
        reqRes: (
          req: reqRes.req,
          res: Response.from(reqRes.req).json(hdlrResult)
        )
      );
    }

    return (
      canNext: canNext,
      reqRes: (
        req: reqRes.req,
        res: Response.from(reqRes.req).ok(hdlrResult.toString()),
      ),
    );
  }
}

typedef RequestHandlerFunc = FutureOr<dynamic> Function(
  $Request req,
  Response res,
);

class RequestHandler extends RouteHandler<RequestHandlerFunc> {
  final RequestHandlerFunc _func;
  final Route _route;

  RequestHandler(this._func, this._route);

  @override
  RequestHandler prefix(String prefix) =>
      RequestHandler(_func, route.withPrefix(prefix));

  @override
  RequestHandlerFunc get handler => _func;

  @override
  Route get route => _route;

  @override
  bool get internal => false;

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

class Middleware extends RouteHandler<MiddlewareFunc> {
  final MiddlewareFunc _func;
  final Route _route;
  Middleware(this._func, this._route);

  @override
  Middleware prefix(String prefix) => Middleware(
        _func,
        route.withPrefix(prefix),
      );

  @override
  MiddlewareFunc get handler => (req, res, _) => _func(
        req,
        res,
        () => next(),
      );

  @override
  Route get route => _route;

  @override
  bool get internal => false;
}

class InternalMiddleware extends Middleware {
  InternalMiddleware(super.func, super.route);
  @override
  bool get internal => true;
}
