part of '../router.dart';

sealed class RouterContract {
  void get(String path, RequestHandler hdler);

  void post(String path, RequestHandler hdler);

  void put(String path, RequestHandler hdler);

  void delete(String path, RequestHandler hdler);

  void head(String path, RequestHandler hdler);

  void patch(String path, RequestHandler hdler);

  void options(String path, RequestHandler hdler);

  void trace(String path, RequestHandler hdler);

  void use(Middleware middleware);

  void on(String path, Middleware hdler, {HTTPMethod method = HTTPMethod.ALL});
}

mixin RouteDefinitionMixin on RouterContract {
  late Spanner spanner;

  void useSpanner(Spanner router) {
    spanner = router;
  }

  @override
  void delete(String path, RequestHandler hdler) {
    spanner.addRoute(HTTPMethod.DELETE, path, useRequestHandler(hdler));
  }

  @override
  void get(String path, RequestHandler hdler) {
    spanner.addRoute(HTTPMethod.GET, path, useRequestHandler(hdler));
  }

  @override
  void head(String path, RequestHandler hdler) {
    spanner.addRoute(HTTPMethod.HEAD, path, useRequestHandler(hdler));
  }

  @override
  void options(String path, RequestHandler hdler) {
    spanner.addRoute(HTTPMethod.OPTIONS, path, useRequestHandler(hdler));
  }

  @override
  void patch(String path, RequestHandler hdler) {
    spanner.addRoute(HTTPMethod.PATCH, path, useRequestHandler(hdler));
  }

  @override
  void post(String path, RequestHandler hdler) {
    spanner.addRoute(HTTPMethod.POST, path, useRequestHandler(hdler));
  }

  @override
  void put(String path, RequestHandler hdler) {
    spanner.addRoute(HTTPMethod.PUT, path, useRequestHandler(hdler));
  }

  @override
  void trace(String path, RequestHandler hdler) {
    spanner.addRoute(HTTPMethod.TRACE, path, useRequestHandler(hdler));
  }

  @override
  void use(Middleware middleware) {
    spanner.addMiddleware(BASE_PATH, middleware);
  }

  @override
  void on(
    String path,
    Middleware middleware, {
    HTTPMethod method = HTTPMethod.ALL,
  }) {
    if (method == HTTPMethod.ALL) {
      spanner.addMiddleware(path, middleware);
    } else {
      spanner.addRoute(method, path, middleware);
    }
  }
}
