import 'package:path_to_regexp/path_to_regexp.dart';

import '../http/request.dart';
import 'handler.dart';
import 'router.dart';

class Route {
  final String path;
  final List<HTTPMethod> verbs;
  final String? prefix;

  String get route {
    if (prefix == null) return path;
    if (path == ANY_PATH) return '$prefix';
    return '$prefix$path';
  }

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

    /// This matches routes correctly until you register
    /// a handler on a prefix eg: `/api/v1`.
    /// In order for it to still be a match to /api/v1/whatever-comes-after
    /// you need to set prefix: true.
    /// Hence if [prefix != null] prefix should be true
    return pathToRegExp(route, prefix: prefix != null).hasMatch(request.path);
  }
}

class RouteGroup {
  final String prefix;
  final List<RouteHandler> handlers = [];

  RouteGroup(this.prefix);

  void add(RouteHandler handler) {
    if (handler.route.route.trim().isEmpty) {
      throw Exception('Routes should being with $BASE_PATH');
    }

    if (![BASE_PATH, ANY_PATH].contains(prefix)) {
      handler = handler.prefix(prefix);
    }

    /// TODO(codekeyz) do checks here to make sure there's no duplicate entry in the routes
    handlers.add(handler);
  }

  List<RouteHandler> findHandlers(Request request) => handlers.isEmpty
      ? []
      : handlers.where((e) => e.route.canHandle(request)).toList();
}
