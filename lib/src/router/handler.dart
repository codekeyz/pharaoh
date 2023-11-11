import 'dart:async';

import '../request.dart';
import '../response.dart';
import 'route.dart';

typedef ReqRes = (Request req, Response res);

typedef ProcessHandlerFunc = (ReqRes data, HandlerFunc handler);

typedef HandlerFunc = FutureOr<dynamic> Function(Request req, Response res);

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
  RequestHandler(super.handler, super.route);
}

class Middleware extends RouteHandler {
  Middleware(super.handler, super.route);
}
