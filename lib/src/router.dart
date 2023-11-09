// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:io';

typedef Handler = Function(HttpRequest req);

enum HTTPMethod {
  GET,
  HEAD,
  POST,
  PUT,
  DELETE,
}

class BasicRoute {
  final List<HTTPMethod> methods;
  final String pattern;
  final Handler handler;

  const BasicRoute(
    this.pattern, {
    this.methods = const [],
    required this.handler,
  });
}

mixin RouterContract {
  List<BasicRoute> get routes;

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
  final List<BasicRoute> _routeBag;

  PharoahRouter() : _routeBag = [];

  @override
  void get(String path, Handler handler) {
    final route = BasicRoute(
      path,
      methods: [HTTPMethod.GET, HTTPMethod.HEAD],
      handler: handler,
    );
    _routeBag.add(route);
  }

  @override
  void post(String path, Handler handler) {
    final route = BasicRoute(
      path,
      methods: [HTTPMethod.POST],
      handler: handler,
    );
    _routeBag.add(route);
  }

  @override
  void put(String path, Handler handler) {
    final route = BasicRoute(
      path,
      methods: [HTTPMethod.PUT],
      handler: handler,
    );
    _routeBag.add(route);
  }

  @override
  void delete(String path, Handler handler) {
    final route = BasicRoute(
      path,
      methods: [HTTPMethod.DELETE],
      handler: handler,
    );
    _routeBag.add(route);
  }

  @override
  Future handleRequest(HttpRequest request) async {}

  @override
  FutureOr<Router> commit() async {
    return this;
  }

  @override
  List<BasicRoute> get routes => _routeBag;
}
