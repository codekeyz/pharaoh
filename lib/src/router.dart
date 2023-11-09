// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:pharaoh/src/utils.dart';

typedef Handler = Function(HttpRequest req);

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
  final Handler handler;

  const RequestHandler(
    this.pattern, {
    this.methods = const [],
    required this.handler,
  });
}

mixin RouterContract {
  List<RequestHandler> get routes;

  void get(String path, Handler handler);

  void post(String path, Handler handler);

  void put(String path, Handler handler);

  void delete(String path, Handler handler);
}

abstract class Router with RouterContract {
  static Router get getInstance => PharoahRouter();

  Future<dynamic> handleRequest(HttpRequest request);

  FutureOr<Router> commit();
}

class PharoahRouter extends Router {
  final List<RequestHandler> _routeBag;

  PharoahRouter() : _routeBag = [];

  @override
  void get(String path, Handler handler) {
    final route = RequestHandler(
      path,
      methods: [HTTPMethod.GET, HTTPMethod.HEAD],
      handler: handler,
    );
    _routeBag.add(route);
  }

  @override
  void post(String path, Handler handler) {
    final route = RequestHandler(
      path,
      methods: [HTTPMethod.POST],
      handler: handler,
    );
    _routeBag.add(route);
  }

  @override
  void put(String path, Handler handler) {
    final route = RequestHandler(
      path,
      methods: [HTTPMethod.PUT],
      handler: handler,
    );
    _routeBag.add(route);
  }

  @override
  void delete(String path, Handler handler) {
    final route = RequestHandler(
      path,
      methods: [HTTPMethod.DELETE],
      handler: handler,
    );
    _routeBag.add(route);
  }

  @override
  Future handleRequest(HttpRequest request) async {
    final method = getHttpMethod(request);
    final path = request.uri.toString();
    final response = request.response;

    final route = _findRoute(method, path);
    if (route == null) {
      sendServerError(response, 'Route not found for $path');
      return;
    }

    try {
      final result = await route.handler(request);
      sendJsonResponse(response, result);
    } catch (e) {
      sendServerError(response, 'An error occurred $e');
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
