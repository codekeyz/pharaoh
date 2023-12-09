import 'dart:mirrors';

import 'package:collection/collection.dart';
import 'package:pharaoh/pharaoh.dart';

import '../controller.dart';
import '../method.dart';
import '_middleware.dart';

class ControllerDefinition {
  final Controller meta;
  final List<ControllerMethodDefinition> methodDefns;
  final List<MiddlewareDefinition> middlewareDefns;
  final InstanceMirror instance;

  const ControllerDefinition(
    this.meta, {
    this.methodDefns = const [],
    this.middlewareDefns = const [],
    required this.instance,
  });

  ControllerDefinition withApp(Pharaoh app) {
    return ControllerDefinition(
      meta,
      methodDefns: methodDefns,
      middlewareDefns: middlewareDefns,
      instance: instance..invoke(#setAppInstance, [app]),
    );
  }
}

class ControllerMethodDefinition {
  final Symbol name;
  final Middleware handler;
  final routeMapping mapping;

  const ControllerMethodDefinition(this.name, this.mapping, this.handler);
}

class PharaohAnnotationError extends PharaohException {
  PharaohAnnotationError(
    String message, {
    Object? value,
  }) : super.value(message, value);

  @override
  String get parentName => 'Pharaoh Annotation Error';
}

Middleware _makeHandler(InstanceMirror parent, MethodMirror methodMirror) {
  return useRequestHandler((req, res) async {
    final result = await Future.sync(
      () => parent.invoke(methodMirror.simpleName, [req, res]),
    );
    return result.reflectee;
  });
}

routeMapping _getMapping(MethodMirror methodMirror) {
  final routeMappings =
      methodMirror.metadata.where((e) => e.type.isSubtypeOf(reflectType(routeMapping)));
  if (routeMappings.length > 1) {
    throw PharaohAnnotationError('Methods can have only one RouteMapping',
        value: routeMappings.toList().sublist(1));
  }
  return routeMappings.first.reflectee as routeMapping;
}

ControllerDefinition buildControllerDefinition(BaseController ctrl) {
  final ctrlMirror = reflect(ctrl);
  final controllerAnnotations = ctrlMirror.type.metadata;
  final members = ctrlMirror.type.instanceMembers;

  /// resolving @Controller annotation on [ctrl]
  final controllerAnnotation = controllerAnnotations
      .firstWhereOrNull((e) => e.type.isSubtypeOf(reflectType(Controller)));
  if (controllerAnnotation == null) {
    throw PharaohAnnotationError('Class has missing @Controller annotation', value: ctrl);
  }

  final List<ControllerMethodDefinition> methodDefns = members.values
      .whereType<MethodMirror>()
      .where((e) => e.metadata.any((e) => e.type.isSubtypeOf(reflectType(routeMapping))))
      .map<ControllerMethodDefinition>((e) => ControllerMethodDefinition(
          e.simpleName, _getMapping(e), _makeHandler(ctrlMirror, e)))
      .toList();

  final middlewareDefns =
      ctrlMirror.getField(#middlewares).reflectee as Set<MiddlewareDefinition>;

  return ControllerDefinition(
    controllerAnnotation.reflectee,
    methodDefns: methodDefns,
    middlewareDefns: middlewareDefns.toList(),
    instance: ctrlMirror,
  );
}
