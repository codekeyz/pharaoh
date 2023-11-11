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
typedef HandlerFunc = FutureOr<dynamic> Function(Request req, Response res);

/// This type of handler uses the Request interface [$Request]
/// which is nothing but an interface. All you have on this are getter calls
/// to get information about Requests reaching your application
typedef RequestHandlerFunc = FutureOr<dynamic> Function(
  $Request req,
  Response res,
);

/// All route handler types must extend this class.
///
/// See: [RequestHandler] and [Middleware] types
abstract class RouteHandler {
  Route route;
  final HandlerFunc handler;
  RouteHandler(this.handler, this.route);
  RouteHandler prefix(String prefix) {
    route = route.withPrefix(prefix);
    return this;
  }
}

class RequestHandler extends RouteHandler {
  RequestHandler(RequestHandlerFunc func, Route route) : super(func, route);
}

class Middleware extends RouteHandler {
  Middleware(super.handler, super.route);
}
