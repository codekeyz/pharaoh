import 'package:path_to_regexp/path_to_regexp.dart';

import '../request.dart';
import 'router.dart';

class Route {
  final String path;
  final List<HTTPMethod> verbs;
  final String? prefix;

  String get route => prefix == null ? path : '$prefix$path';

  const Route(
    this.path,
    this.verbs, {
    this.prefix,
  });

  /// Any path with the following methods [HTTPMethod]
  Route.all([HTTPMethod method = HTTPMethod.ALL])
      : verbs = [method],
        path = ANY_PATH,
        prefix = null;

  /// Any path or method
  Route.any()
      : verbs = [],
        path = ANY_PATH,
        prefix = null;

  Route withPrefix(String prefix) => Route(
        path,
        verbs,
        prefix: prefix,
      );

  bool canHandle(Request request) {
    final anyMethod = verbs.isEmpty;
    if (!anyMethod) {
      final canMethod =
          verbs[0] == HTTPMethod.ALL || verbs.contains(request.method);
      if (!canMethod) return false;
    }
    if (route == ANY_PATH) return true;
    return pathToRegExp(route).hasMatch(request.path);
  }
}

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
