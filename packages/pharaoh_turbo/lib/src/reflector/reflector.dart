import 'package:pharaoh/pharaoh.dart';

import '../../pharaoh_turbo.dart';
import '_controller.dart';
import '_middleware.dart';

Future<void> useController(Pharaoh app, BaseController ctrl) async {
  final definition = buildControllerDefinition(ctrl).withApp(app);
  final basePath = definition.meta.path;
  final methodDefns = definition.methodDefns;
  final middlewareDefs = definition.middlewareDefns;
  final scopedMdws = <MiddlewareDefinition>[];

  for (final definition in middlewareDefs) {
    if (definition.methods.isNotEmpty) {
      scopedMdws.add(definition);
      continue;
    }
    app.on(basePath, definition.mdw);
  }

  /// check and ensure all scoped method symbols actually exist
  /// as methods in the controller class
  final controllerMethodNames = methodDefns.map((e) => e.name).toList();
  final invalidSymbols = <Symbol>[];
  for (final mdw in scopedMdws) {
    final methods = mdw.methods.where((e) => !controllerMethodNames.contains(e));
    invalidSymbols.addAll(methods);
  }
  if (invalidSymbols.isNotEmpty) {
    throw ArgumentError.value(invalidSymbols.map((e) => e.toString()).join(', '), null,
        'Not existent methods in Middleware Scope');
  }

  final scopedMethods = methodDefns
      .where((e) => scopedMdws.any((scopedMdw) => scopedMdw.methods.contains(e.name)))
      .map((e) {
    final methodMdws =
        scopedMdws.where((scopedMdw) => scopedMdw.methods.contains(e.name));

    final chainedHandler = methodMdws
        .map((e) => e.mdw)
        .reduce((handler, newHandler) => handler.chain(newHandler))
        .chain(e.handler);
    return ControllerMethodDefinition(e.name, e.mapping, chainedHandler);
  }).toList();

  final unscopedMethods =
      methodDefns.where((e) => !scopedMethods.any((scoped) => scoped.name == e.name));

  for (final methodDefn in [...scopedMethods, ...unscopedMethods]) {
    final fullPath = basePath + methodDefn.mapping.path;
    final methods = methodDefn.mapping.methods;

    if (methods.contains(HTTPMethod.ALL)) {
      app.on(fullPath, methodDefn.handler, method: HTTPMethod.ALL);
      continue;
    }

    for (final method in methods) {
      app.on(fullPath, methodDefn.handler, method: method);
    }
  }
}
