import 'package:path_to_regexp/path_to_regexp.dart';

import 'router.dart';

class Route {
  final String _route;
  final List<HTTPMethod> verbs;
  final String? prefix;

  String get route => prefix == null ? _route : '$prefix$_route';

  const Route(
    this._route,
    this.verbs, {
    this.prefix,
  });

  /// Any route with the following [HTTPMethod]
  Route.all([HTTPMethod method = HTTPMethod.ALL])
      : verbs = [method],
        _route = ANY_PATH,
        prefix = null;

  /// Any route or method
  Route.any()
      : verbs = [],
        _route = ANY_PATH,
        prefix = null;

  Route withPrefix(String prefix) => Route(
        route,
        verbs,
        prefix: prefix,
      );

  bool canHandle(HTTPMethod method, String path) {
    final anyMethod = verbs.isEmpty;
    if (!anyMethod) {
      final canMethod = verbs[0] == HTTPMethod.ALL || verbs.contains(method);
      if (!canMethod) return false;
    }
    if (route == ANY_PATH) return true;
    return pathToRegExp(route).hasMatch(path);
  }
}

class RouteGroup {
  String prefix;
  List<RouteHandler> handlers;

  RouteGroup(this.prefix) : handlers = [];

  void add(RouteHandler handler) {
    final route = handler.route;
    if (route.route.trim().isEmpty) {
      throw Exception('Routes should being with $BASE_PATH');
    }

    if (![BASE_PATH, ANY_PATH].contains(prefix)) {
      handler.route = route.withPrefix(prefix);
    }

    /// TODO: do checks here to make sure there's no duplicate entry in the routes
    handlers.add(handler);
  }

  List<RouteHandler> findHandlers(HTTPMethod method, String path) {
    return handlers.where((e) => e.route.canHandle(method, path)).toList();
  }
}

abstract class RouteHandler {
  Route route;
  final HandlerFunc handler;
  RouteHandler(this.handler, this.route);
}

class RequestHandler extends RouteHandler {
  RequestHandler(super.handler, super.route);
}

class Middleware extends RouteHandler {
  Middleware(super.handler, super.route);
}
