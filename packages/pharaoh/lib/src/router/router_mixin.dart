import 'package:spanner/spanner.dart';

import '../http/request.dart';
import 'router_contract.dart';
import 'router_handler.dart';

mixin RouteDefinitionMixin on RouterContract {
  late final Spanner spanner;

  void useSpanner(Spanner router) {
    spanner = router;
  }

  @override
  void delete(String path, RequestHandlerFunc hdler) {
    spanner.on(HTTPMethod.DELETE, path, useRequestHandler(hdler));
  }

  @override
  void get(String path, RequestHandlerFunc hdler) {
    spanner.on(HTTPMethod.GET, path, useRequestHandler(hdler));
  }

  @override
  void head(String path, RequestHandlerFunc hdler) {
    spanner.on(HTTPMethod.HEAD, path, useRequestHandler(hdler));
  }

  @override
  void options(String path, RequestHandlerFunc hdler) {
    spanner.on(HTTPMethod.OPTIONS, path, useRequestHandler(hdler));
  }

  @override
  void patch(String path, RequestHandlerFunc hdler) {
    spanner.on(HTTPMethod.PATCH, path, useRequestHandler(hdler));
  }

  @override
  void post(String path, RequestHandlerFunc hdler) {
    spanner.on(HTTPMethod.POST, path, useRequestHandler(hdler));
  }

  @override
  void put(String path, RequestHandlerFunc hdler) {
    spanner.on(HTTPMethod.PUT, path, useRequestHandler(hdler));
  }

  @override
  void trace(String path, RequestHandlerFunc hdler) {
    spanner.on(HTTPMethod.TRACE, path, useRequestHandler(hdler));
  }

  @override
  void use(HandlerFunc middleware) {
    spanner.on(HTTPMethod.ALL, '*', middleware);
  }

  @override
  void on(
    String path,
    HandlerFunc middleware, {
    HTTPMethod method = HTTPMethod.ALL,
  }) {
    spanner.on(method, '$path', middleware);
  }
}
