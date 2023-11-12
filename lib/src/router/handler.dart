import 'dart:async';

import '../http/request.dart';
import '../http/response.dart';
import 'route.dart';

typedef ReqRes = (Request req, Response res);

typedef ProcessHandlerFunc = (ReqRes data, HandlerFunc handler);

/// This type of handler allows you to use the actual
/// request instance [Request].
///
/// This way you can reprocess contents in the
/// request before it reaches other handlers in your application.
///
/// See here: [Middleware]
typedef HandlerFunc = FutureOr<dynamic> Function(Request req, Response res);

/// This type of handler uses the Request interface [$Request]
/// which is nothing but an interface. All you have on this are getter calls
/// to get information about Requests reaching your application
///
/// See here: [RequestHandler]
typedef RequestHandlerFunc = FutureOr<dynamic> Function(
  $Request req,
  Response res,
);

/// All route handler types must extend this class.
///
/// See: [RequestHandler] and [Middleware] types
abstract interface class RouteHandler {
  Route get route;
  HandlerFunc get handler;
  RouteHandler prefix(String prefix);
}

class RequestHandler implements RouteHandler {
  final RequestHandlerFunc _func;
  final Route _route;
  const RequestHandler(this._func, this._route);

  @override
  RequestHandler prefix(String prefix) =>
      RequestHandler(_func, route.withPrefix(prefix));

  @override
  HandlerFunc get handler => _func;

  @override
  Route get route => _route;
}

class Middleware implements RouteHandler {
  final HandlerFunc _func;
  final Route _route;
  const Middleware(this._func, this._route);

  @override
  Middleware prefix(String prefix) =>
      Middleware(_func, route.withPrefix(prefix));

  @override
  HandlerFunc get handler => _func;

  @override
  Route get route => _route;
}
