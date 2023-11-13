import 'package:collection/collection.dart';
import 'package:path_to_regexp/path_to_regexp.dart';

import '../http/request.dart';
import '../utils/exceptions.dart';
import 'handler.dart';
import 'router.dart';

String verbString(List<HTTPMethod> verbs) => verbs.map((e) => e.name).join(':');

class Route {
  final String? path;
  final List<HTTPMethod> verbs;
  final String? prefix;

  String? get route {
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
    final fullRoute = route;
    if (fullRoute == null) return false;

    if (route == null) return false;
    final canMethod =
        verbs.contains(HTTPMethod.ALL) || verbs.contains(request.method);
    if (!canMethod) return false;
    if (route == ANY_PATH) return true;
    return pathToRegExp(fullRoute, prefix: true).hasMatch(request.path);
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

const reservedPaths = [BASE_PATH, ANY_PATH];

class RouteGroup {
  final String? prefix;
  final List<RouteHandler> handlers;

  RouteGroup._({
    this.prefix,
    List<RouteHandler>? handlers,
  }) : handlers = handlers ?? [];

  RouteGroup.path(String path)
      : prefix = path,
        handlers = [];

  RouteGroup withPrefix(String prefix) => RouteGroup._(
        prefix: prefix,
        handlers: handlers,
      );

  /// Adding routes the the current group does a very simple
  /// check to make sure we don't have multiple [RequestHandler]
  /// registered on the same route. See: [Route.isSameAs].
  void add(RouteHandler newHandler) {
    final newRoute = newHandler.route.route?.trim() ?? '';
    if (newRoute.isEmpty) {
      throw PharoahException('Route cannot be an empty string');
    } else if (!reservedPaths.contains(newRoute[0])) {
      throw PharoahException.value('Route should be with $BASE_PATH', newRoute);
    }

    if (!reservedPaths.contains(prefix)) {
      newHandler = newHandler.prefix(prefix!);
    }

    final existingHandler = handlers.firstWhereOrNull(
        (e) => e.route.isSameAs(newHandler.route) && e is RequestHandler);
    if (existingHandler != null && newHandler is RequestHandler) {
      final route = existingHandler.route;
      throw PharoahException.value(
        'Request handler already registered for route',
        '${verbString(route.verbs)} on ${route.route}',
      );
    }

    handlers.add(newHandler);
  }

  List<RouteHandler> findHandlers(Request request) => findHandlersForRequest(
        request,
        handlers,
      );
}

List<RouteHandler> findHandlersForRequest(
  Request request,
  List<RouteHandler> handlers,
) =>
    handlers.isEmpty
        ? []
        : handlers.where((e) => e.route.canHandle(request)).toList();
