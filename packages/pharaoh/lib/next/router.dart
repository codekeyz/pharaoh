library router;

import 'package:grammer/grammer.dart';
import 'package:meta/meta.dart';

import '_validation/dto.dart';
import '_router/meta.dart';
import '_core/reflector.dart';
import '_router/utils.dart';
import 'core.dart';

export 'package:spanner/spanner.dart' show HTTPMethod;

part '_router/definition.dart';

abstract interface class Route {
  static UseAliasedMiddleware middleware(String name) =>
      UseAliasedMiddleware(name);

  static ControllerRouteMethodDefinition get(
    String path,
    ControllerMethodDefinition defn,
  ) =>
      ControllerRouteMethodDefinition(
          defn, RouteMapping([HTTPMethod.GET], path));

  static ControllerRouteMethodDefinition head(
          String path, ControllerMethodDefinition defn) =>
      ControllerRouteMethodDefinition(
          defn, RouteMapping([HTTPMethod.HEAD], path));

  static ControllerRouteMethodDefinition post(
          String path, ControllerMethodDefinition defn) =>
      ControllerRouteMethodDefinition(
          defn, RouteMapping([HTTPMethod.POST], path));

  static ControllerRouteMethodDefinition put(
          String path, ControllerMethodDefinition defn) =>
      ControllerRouteMethodDefinition(
          defn, RouteMapping([HTTPMethod.PUT], path));

  static ControllerRouteMethodDefinition delete(
          String path, ControllerMethodDefinition defn) =>
      ControllerRouteMethodDefinition(
          defn, RouteMapping([HTTPMethod.DELETE], path));

  static ControllerRouteMethodDefinition patch(
          String path, ControllerMethodDefinition defn) =>
      ControllerRouteMethodDefinition(
          defn, RouteMapping([HTTPMethod.PATCH], path));

  static ControllerRouteMethodDefinition options(
          String path, ControllerMethodDefinition defn) =>
      ControllerRouteMethodDefinition(
          defn, RouteMapping([HTTPMethod.OPTIONS], path));

  static ControllerRouteMethodDefinition trace(
          String path, ControllerMethodDefinition defn) =>
      ControllerRouteMethodDefinition(
          defn, RouteMapping([HTTPMethod.TRACE], path));

  static ControllerRouteMethodDefinition mapping(
    List<HTTPMethod> methods,
    String path,
    ControllerMethodDefinition defn,
  ) {
    var mapping = RouteMapping(methods, path);
    if (methods.contains(HTTPMethod.ALL)) {
      mapping = RouteMapping([HTTPMethod.ALL], path);
    }
    return ControllerRouteMethodDefinition(defn, mapping);
  }

  static RouteGroupDefinition group(String name, List<RouteDefinition> routes,
          {String? prefix}) =>
      RouteGroupDefinition._(name, definitions: routes, prefix: prefix);

  static RouteGroupDefinition resource(String resource, Type controller,
      {String? parameterName}) {
    resource = resource.toLowerCase();

    final resourceId =
        '${(parameterName ?? resource).toSingular().toLowerCase()}Id';

    return Route.group(resource, [
      Route.get('/', (controller, #index)),
      Route.get('/<$resourceId>', (controller, #show)),
      Route.post('/', (controller, #create)),
      Route.put('/<$resourceId>', (controller, #update)),
      Route.patch('/<$resourceId>', (controller, #update)),
      Route.delete('/<$resourceId>', (controller, #delete))
    ]);
  }

  static FunctionalRouteDefinition route(
    HTTPMethod method,
    String path,
    RequestHandler handler,
  ) =>
      FunctionalRouteDefinition.route(method, path, handler);

  static FunctionalRouteDefinition notFound(
    RequestHandler handler, [
    HTTPMethod method = HTTPMethod.ALL,
  ]) =>
      Route.route(method, '/*', handler);
}

Middleware useAliasedMiddleware(String alias) =>
    ApplicationFactory.resolveMiddlewareForGroup(alias)
        .reduce((val, e) => val.chain(e));
