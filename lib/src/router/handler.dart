import 'dart:async';

import '../http/request.dart';
import '../http/response.dart';
import '../utils/exceptions.dart';
import 'route.dart';

typedef ReqRes = ({Request req, Response res});

typedef NextFunction = dynamic Function([dynamic result]);

/// This type of handler allows you to use the actual
/// request instance [Request].
///
/// This way you can reprocess contents in the
/// request before it reaches other handlers in your application.
///
/// See here: [Middleware]
typedef HandlerFunc = Function(Request req, Response res, NextFunction next);

typedef HandlerResult = ({bool canNext, ReqRes reqRes});

/// All route handler types must extend this class.
///
/// See: [RequestHandler] and [Middleware] types
abstract class RouteHandler {
  Route get route;
  HandlerFunc get handler;

  Map<String, String> _routeParams = {};

  Map<String, String> get params => _routeParams;

  void setParams(Map<String, String> params) {
    _routeParams = params;
  }

  RouteHandler prefix(String prefix);

  Future<HandlerResult> handle(final ReqRes reqRes) async {
    final request = reqRes.req;
    if (_routeParams.isNotEmpty) {
      for (final param in params.entries) {
        request.updateParams(param.key, param.value);
      }
    }

    ReqRes result = reqRes;
    bool canGotoNext = false;

    await handler(request, reqRes.res, ([nr_]) {
      if (nr_ != null && nr_ is! Request && nr_ is! Response) {
        throw PharaohException.value(
            'Next Function result can only be Request or Response');
      }

      if (nr_ is Request) result = (req: nr_, res: reqRes.res);
      if (nr_ is Response) result = (req: reqRes.req, res: nr_);
      canGotoNext = true;
    });

    return (canNext: canGotoNext, reqRes: result);
  }
}

typedef RequestHandlerFunc = FutureOr<dynamic> Function(
  $Request req,
  $Response res,
);

/// - [RequestHandler] calls `next` automatically,
///  hence the reason there's no next function. See [RequestHandlerFunc].
class RequestHandler extends RouteHandler {
  final RequestHandlerFunc _func;
  final Route _route;

  RequestHandler(this._func, this._route);

  @override
  RequestHandler prefix(String prefix) => RequestHandler(
        _func,
        route.withPrefix(prefix),
      );

  @override
  HandlerFunc get handler => (req, res, next_) async {
        final result = await _func(req, res);
        next_(result);
      };

  @override
  Route get route => _route;
}

/// With middlewares, you get a `req`, `res`, and `next` function.
/// you do your processing and then notify us to proceed when you call `next`.
class Middleware extends RouteHandler {
  final HandlerFunc _func;
  final Route _route;
  Middleware(this._func, this._route);

  @override
  Middleware prefix(String prefix) => Middleware(
        _func,
        route.withPrefix(prefix),
      );

  @override
  HandlerFunc get handler => (req, res, next_) => _func(req, res, next_);

  @override
  Route get route => _route;
}
