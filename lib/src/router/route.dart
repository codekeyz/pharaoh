import 'package:path_to_regexp/path_to_regexp.dart';

import '../http/request.dart';
import 'handler.dart';
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
  Route.any([HTTPMethod method = HTTPMethod.ALL])
      : verbs = [method],
        path = ANY_PATH,
        prefix = null;

  Route withPrefix(String prefix) => Route(
        path,
        verbs,
        prefix: prefix,
      );

  bool canHandle(Request request) {
    final canMethod =
        verbs.contains(HTTPMethod.ALL) || verbs.contains(request.method);
    if (!canMethod) return false;
    if (route == ANY_PATH) return true;
    return pathToRegExp(route).hasMatch(request.path);
  }
}

class RouteGroup {
  final String prefix;
  final List<RouteHandler> handlers = [];

  RouteGroup(this.prefix);

  void add(RouteHandler handler) {
    var route = handler.route;

    if (route.route.trim().isEmpty) {
      throw Exception('Routes should being with $BASE_PATH');
    }

    if (![BASE_PATH, ANY_PATH].contains(prefix)) {
      handler.prefix(prefix);
    }

    /// TODO: do checks here to make sure there's no duplicate entry in the routes
    handlers.add(handler);
  }

  List<RouteHandler> findHandlers(Request request) => handlers.isEmpty
      ? []
      : handlers.where((e) => e.route.canHandle(request)).toList();
}
