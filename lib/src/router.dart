// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:io';
import 'package:collection/collection.dart';

import 'response.dart';

typedef HandlerFunc = Function(HttpRequest req, Response res);

enum HTTPMethod {
  GET,
  HEAD,
  POST,
  PUT,
  DELETE,
}

HTTPMethod getHttpMethod(HttpRequest req) {
  switch (req.method) {
    case 'GET' || 'HEAD':
      return HTTPMethod.GET;
    case 'POST':
      return HTTPMethod.POST;
    case 'PUT':
      return HTTPMethod.PUT;
    case 'DELETE':
      return HTTPMethod.DELETE;
    default:
      throw Exception('Method ${req.method} not yet supported');
  }
}

class RequestHandler {
  final List<HTTPMethod> methods;
  final String pattern;
  final HandlerFunc handler;

  const RequestHandler(
    this.pattern, {
    this.methods = const [],
    required this.handler,
  });
}

mixin RouterContract {
  List<RequestHandler> get routes;

  void get(String path, HandlerFunc handler);

  void post(String path, HandlerFunc handler);

  void put(String path, HandlerFunc handler);

  void delete(String path, HandlerFunc handler);
}

abstract class Router with RouterContract {
  static Router get getInstance => PharoahRouter();

  Future<void> handleRequest(HttpRequest request);

  FutureOr<Router> commit();
}

class PharoahRouter extends Router {
  final List<RequestHandler> _routeBag;

  PharoahRouter() : _routeBag = [];

  @override
  void get(String path, HandlerFunc handler) {
    final route = RequestHandler(
      path,
      methods: [HTTPMethod.GET, HTTPMethod.HEAD],
      handler: handler,
    );
    _routeBag.add(route);
  }

  @override
  void post(String path, HandlerFunc handler) {
    final route = RequestHandler(
      path,
      methods: [HTTPMethod.POST],
      handler: handler,
    );
    _routeBag.add(route);
  }

  @override
  void put(String path, HandlerFunc handler) {
    final route = RequestHandler(
      path,
      methods: [HTTPMethod.PUT],
      handler: handler,
    );
    _routeBag.add(route);
  }

  @override
  void delete(String path, HandlerFunc handler) {
    final route = RequestHandler(
      path,
      methods: [HTTPMethod.DELETE],
      handler: handler,
    );
    _routeBag.add(route);
  }

  @override
  Future<void> handleRequest(HttpRequest request) async {
    final method = getHttpMethod(request);
    final path = request.uri.toString();
    final response = Response.from(request);

    final route = _findRoute(method, path);
    if (route == null) {
      await response.status(HttpStatus.notFound).json({
        "message": "No handler found for path :$path",
        "path": path,
      });
      return;
    }

    try {
      final result = await route.handler(request, Response.from(request));
      if (result.runtimeType == Null) return;
      await response.json(result);
    } catch (e) {
      await response
          .status(HttpStatus.internalServerError)
          .json({"message": "An error occurred", "path": path});
    }
  }

  RequestHandler? _findRoute(HTTPMethod method, String path) {
    return _routeBag.firstWhereOrNull(
      (route) =>
          route.methods.contains(method) && _matchPath(route.pattern, path),
    );
  }

  bool _matchPath(String routePath, String requestPath) {
    return routePath == requestPath;
  }

  @override
  FutureOr<Router> commit() async {
    return this;
  }

  @override
  List<RequestHandler> get routes => _routeBag;
}
