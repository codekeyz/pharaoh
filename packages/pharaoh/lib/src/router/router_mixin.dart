import 'package:spanner/spanner.dart';

import '../http/request.dart';
import 'handler.dart';
import 'router.dart';

mixin RouterMixin<T> on RoutePathDefinitionContract<T> {
  late final Router spanner;

  void setRouter(Router router) {
    this.spanner = router;
  }

  @override
  T delete(String path, RequestHandlerFunc hdler) {
    spanner.on(HTTPMethod.DELETE, path, RequestHandler(hdler));
    return this as T;
  }

  @override
  T get(String path, RequestHandlerFunc hdler) {
    spanner.on(HTTPMethod.GET, path, RequestHandler(hdler));
    spanner.on(HTTPMethod.HEAD, path, RequestHandler(hdler));
    return this as T;
  }

  @override
  T head(String path, RequestHandlerFunc hdler) {
    spanner.on(HTTPMethod.HEAD, path, RequestHandler(hdler));
    return this as T;
  }

  @override
  T options(String path, RequestHandlerFunc hdler) {
    spanner.on(HTTPMethod.OPTIONS, path, RequestHandler(hdler));
    return this as T;
  }

  @override
  T patch(String path, RequestHandlerFunc hdler) {
    spanner.on(HTTPMethod.PATCH, path, RequestHandler(hdler));
    return this as T;
  }

  @override
  T post(String path, RequestHandlerFunc hdler) {
    spanner.on(HTTPMethod.POST, path, RequestHandler(hdler));
    return this as T;
  }

  @override
  T put(String path, RequestHandlerFunc hdler) {
    spanner.on(HTTPMethod.PUT, path, RequestHandler(hdler));
    return this as T;
  }

  @override
  T trace(String path, RequestHandlerFunc hdler) {
    spanner.on(HTTPMethod.TRACE, path, RequestHandler(hdler));
    return this as T;
  }

  @override
  T use(HandlerFunc mdw) {
    spanner.on(HTTPMethod.ALL, '/', Middleware(mdw));
    return this as T;
  }

  @override
  T useOnPath(
    String path,
    HandlerFunc mdw, {
    HTTPMethod method = HTTPMethod.ALL,
  }) {
    spanner.on(method, path, Middleware(mdw));
    return this as T;
  }
}
