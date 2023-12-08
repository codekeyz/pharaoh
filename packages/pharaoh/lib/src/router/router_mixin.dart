import 'package:spanner/spanner.dart';

import '../http/request.dart';
import 'router_contract.dart';
import 'router_handler.dart';

mixin RouteDefinitionMixin<T> on RouterContract<T> {
  late final Spanner spanner;

  void useSpanner(Spanner router) {
    spanner = router;
  }

  @override
  T delete(String path, RequestHandlerFunc hdler) {
    spanner.on(HTTPMethod.DELETE, path, useRequestHandler(hdler));
    return this as T;
  }

  @override
  T get(String path, RequestHandlerFunc hdler) {
    spanner.on(HTTPMethod.GET, path, useRequestHandler(hdler));
    return this as T;
  }

  @override
  T head(String path, RequestHandlerFunc hdler) {
    spanner.on(HTTPMethod.HEAD, path, useRequestHandler(hdler));
    return this as T;
  }

  @override
  T options(String path, RequestHandlerFunc hdler) {
    spanner.on(HTTPMethod.OPTIONS, path, useRequestHandler(hdler));
    return this as T;
  }

  @override
  T patch(String path, RequestHandlerFunc hdler) {
    spanner.on(HTTPMethod.PATCH, path, useRequestHandler(hdler));
    return this as T;
  }

  @override
  T post(String path, RequestHandlerFunc hdler) {
    spanner.on(HTTPMethod.POST, path, useRequestHandler(hdler));
    return this as T;
  }

  @override
  T put(String path, RequestHandlerFunc hdler) {
    spanner.on(HTTPMethod.PUT, path, useRequestHandler(hdler));
    return this as T;
  }

  @override
  T trace(String path, RequestHandlerFunc hdler) {
    spanner.on(HTTPMethod.TRACE, path, useRequestHandler(hdler));
    return this as T;
  }

  @override
  T use(HandlerFunc middleware) {
    spanner.on(HTTPMethod.ALL, '*', middleware);
    return this as T;
  }

  @override
  T on(
    String path,
    HandlerFunc middleware, {
    HTTPMethod method = HTTPMethod.ALL,
  }) {
    if (method == HTTPMethod.ALL) path = '$path/*';
    spanner.on(method, '$path', middleware);
    return this as T;
  }
}
