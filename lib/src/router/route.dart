import 'package:collection/collection.dart';
import 'package:path_to_regexp/path_to_regexp.dart';

import '../http/request.dart';
import '../utils/exceptions.dart';
import 'handler.dart';
import 'router.dart';

String verbString(List<HTTPMethod> verbs) => verbs.map((e) => e.name).join(':');

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

  /// This is implemented in such a way that if a [Route]
  /// is already registered to handle [HTTPMethod.ALL] and you attempt
  /// to add any other method on the same route, it should return true.
  /// because they're the same.
  bool isSameAs(Route other) {
    if (route != other.route) return false;
    if (verbs.contains(HTTPMethod.ALL)) return true;
    final otherVerbs = other.verbs.toSet();
    return verbs.toSet().difference(otherVerbs).isEmpty;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Route && other.route == route && other.verbs == verbs;
  }

  @override
  int get hashCode {
    return route.hashCode ^ verbs.hashCode;
  }

  @override
  String toString() => """ 
  Route:       $route
  Verbs:       ${verbString(verbs)}""";
}

class RouteGroup {
  final String prefix;
  final List<RouteHandler> handlers = [];

  RouteGroup(this.prefix);

  /// Adding routes the the current group does a very simple
  /// check to make sure we don't have multiple [RequestHandler]
  /// registered on the same route. See: [Route.isSameAs].
  void add(RouteHandler newHandler) {
    if (newHandler.route.route.isEmpty) {
      throw PharoahException('Routes should being with $BASE_PATH');
    }

    if (![BASE_PATH, ANY_PATH].contains(prefix)) {
      newHandler = newHandler.prefix(prefix);
    }

    final existingHandler = handlers.firstWhereOrNull(
        (e) => e.route.isSameAs(newHandler.route) && e is RequestHandler);
    if (existingHandler != null && newHandler is RequestHandler) {
      final route = existingHandler.route;
      final errorMsg =
          '${verbString(route.verbs)} Request handler already registered for ${route.route}';
      throw PharoahException(errorMsg);
    }

    handlers.add(newHandler);
  }

  List<RouteHandler> findHandlers(Request request) => handlers.isEmpty
      ? []
      : handlers.where((e) => e.route.canHandle(request)).toList();
}
