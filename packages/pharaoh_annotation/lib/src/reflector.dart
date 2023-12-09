import 'dart:mirrors';

import 'package:pharaoh/pharaoh.dart';
import 'package:collection/collection.dart';

import '../pharaoh_annotation.dart';

class PharaohAnnotationError extends PharaohException {
  PharaohAnnotationError(
    String message, {
    Object? value,
  }) : super.value(message, value);

  @override
  String get parentName => 'Pharaoh Annotation Error';
}

Future<void> setupControllers(Pharaoh app, BaseController ctrl) async {
  final InstanceMirror ctrlMirror = reflect(ctrl);
  final controllerAnnotations = ctrlMirror.type.metadata;
  final members = ctrlMirror.type.instanceMembers;

  /// resolving @Controller annotation on [ctrl]
  final controllerAnnotation = controllerAnnotations
      .firstWhereOrNull((e) => e.type.isSubtypeOf(reflectType(Controller)));
  if (controllerAnnotation == null) {
    throw PharaohAnnotationError('Class has missing @Controller annotation', value: ctrl);
  }
  final controller = controllerAnnotation.reflectee as Controller;
  final basePath = controller.path;

  final middlewares = ctrlMirror.getField(#middlewares).reflectee as Iterable<Middleware>;
  if (middlewares.isNotEmpty) {
    for (final mdw in middlewares) {
      app.on(basePath, mdw);
    }
  }

  final List<_RouteDefinition> definitions = members.values
      .whereType<MethodMirror>()
      .where((e) => e.metadata.any((e) => e.type.isSubtypeOf(reflectType(RouteMapping))))
      .map<_RouteDefinition>((e) => (_getMapping(e), _makeHandler(ctrlMirror, e)))
      .toList();

  for (final definition in definitions) {
    final methods = definition.$1.methods;
    final path = controller.path + definition.$1.path;

    if (methods.contains(HTTPMethod.ALL)) {
      app.on(path, definition.$2, method: HTTPMethod.ALL);
      continue;
    }

    for (final method in methods) {
      app.on(path, definition.$2, method: method);
    }
  }
}

typedef _RouteDefinition = (RouteMapping mapping, Middleware hdl);

Middleware _makeHandler(InstanceMirror parent, MethodMirror methodMirror) {
  return useRequestHandler((req, res) async {
    final result = await Future.sync(
      () => parent.invoke(methodMirror.simpleName, [req, res]),
    );
    return result.reflectee;
  });
}

RouteMapping _getMapping(MethodMirror methodMirror) {
  final routeMappings =
      methodMirror.metadata.where((e) => e.type.isSubtypeOf(reflectType(RouteMapping)));
  if (routeMappings.length > 1) {
    throw PharaohAnnotationError('Methods can have only one RouteMapping',
        value: routeMappings.toList().sublist(1));
  }
  return routeMappings.first.reflectee as RouteMapping;
}
