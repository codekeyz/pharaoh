// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:pharaoh/pharaoh.dart';
import 'package:spookie/spookie.dart' as spookie;

import 'http.dart';
import 'router.dart';

import '_core/container.dart';
import '_core/reflector.dart';
import '_core/config.dart';
export '_core/config.dart';

export 'package:pharaoh/pharaoh.dart';

part '_core/core_impl.dart';

typedef RoutesResolver = List<RouteDefinition> Function();

/// This should really be a mixin but due to a bug in reflectable.dart#324
/// TODO:(codekeyz) make this a mixin when reflectable.dart#324 is fixed
abstract class AppInstance {
  Application get app => Application.instance;
}

/// Use this to override the application exceptiosn handler
typedef ApplicationExceptionsHandler = FutureOr<Response> Function(
  Object exception,
  ReqRes reqRes,
);

abstract interface class Application {
  Application(AppConfig config);

  static late final Application instance;

  String get name;

  String get url;

  int get port;

  AppConfig get config;

  T singleton<T extends Object>(T instance);

  T instanceOf<T extends Object>();

  void useRoutes(RoutesResolver routeResolver);

  void useViewEngine(ViewEngine viewEngine);
}

abstract class ApplicationFactory {
  final AppConfig appConfig;

  List<Type> get providers;

  /// The application's global HTTP middleware stack.
  ///
  /// These middleware are run during every request to your application.
  /// Types here must extends [Middleware].
  List<Type> get middlewares;

  /// The application's route middleware groups.
  ///
  /// Types here must extends [Middleware].
  final Map<String, List<Type>> middlewareGroups = {};

  static Map<String, List<Type>> _middlewareGroups = {};

  Middleware? _globalMdwCache;
  @nonVirtual
  Middleware? get globalMiddleware {
    if (_globalMdwCache != null) return _globalMdwCache!;
    if (middlewares.isEmpty) return null;
    return _globalMdwCache =
        middlewares.map(_buildHandlerFunc).reduce((val, e) => val.chain(e));
  }

  ApplicationFactory(this.appConfig) {
    providers.forEach(ensureIsSubTypeOf<ServiceProvider>);
    middlewares.forEach(ensureIsSubTypeOf<ClassMiddleware>);
    for (final types in middlewareGroups.values) {
      types.map(ensureIsSubTypeOf<ClassMiddleware>);
    }
    _middlewareGroups = middlewareGroups;
  }

  Future<void> bootstrap({bool listen = true}) async {
    await _bootstrapComponents(appConfig);

    if (listen) await startServer();
  }

  Future<void> startServer() async {
    final app = Application.instance as _YarooAppImpl;

    await app
        ._createPharaohInstance(onException: onApplicationException)
        .listen(port: app.port);
  }

  Future<void> _bootstrapComponents(AppConfig config) async {
    final spanner = Spanner()..addMiddleware('/', bodyParser);
    Application.instance = _YarooAppImpl(config, spanner);

    final providerInstances = providers.map(createNewInstance<ServiceProvider>);

    /// register dependencies
    for (final instance in providerInstances) {
      await Future.sync(instance.register);
    }

    if (globalMiddleware != null) {
      spanner.addMiddleware<Middleware>('/', globalMiddleware!);
    }

    /// boot providers
    for (final provider in providerInstances) {
      await Future.sync(provider.boot);
    }
  }

  static RequestHandler buildControllerMethod(ControllerMethod method) {
    final params = method.params;

    return (req, res) {
      final methodName = method.methodName;
      final instance = createNewInstance<HTTPController>(method.controller);
      final mirror = inject.reflect(instance);

      mirror
        ..invokeSetter('request', req)
        ..invokeSetter('response', res);

      late Function() methodCall;

      if (params.isNotEmpty) {
        final args = _resolveControllerMethodArgs(req, method);
        methodCall = () => mirror.invoke(methodName, args);
      } else {
        methodCall = () => mirror.invoke(methodName, []);
      }

      return Future.sync(methodCall);
    };
  }

  static List<Object> _resolveControllerMethodArgs(
      Request request, ControllerMethod method) {
    if (method.params.isEmpty) return [];

    final args = <Object>[];

    for (final param in method.params) {
      final meta = param.meta;
      if (meta != null) {
        args.add(meta.process(request, param));
        continue;
      }
    }
    return args;
  }

  static Iterable<Middleware> resolveMiddlewareForGroup(String group) {
    final middlewareGroup = ApplicationFactory._middlewareGroups[group];
    if (middlewareGroup == null) {
      throw ArgumentError('Middleware group `$group` does not exist');
    }
    return middlewareGroup.map(_buildHandlerFunc);
  }

  static Middleware _buildHandlerFunc(Type type) {
    final instance = createNewInstance<ClassMiddleware>(type);
    return instance.handler ?? instance.handle;
  }

  @visibleForTesting
  Future<spookie.Spookie> get tester {
    final app = (Application.instance as _YarooAppImpl);
    return spookie.request(
        app._createPharaohInstance(onException: onApplicationException));
  }

  FutureOr<Response> onApplicationException(
    PharaohError error,
    Request request,
    Response response,
  ) async {
    final exception = error.exception;
    if (exception is RequestValidationError) {
      return response.json(exception, statusCode: HttpStatus.badRequest);
    } else if (error is SpannerRouteValidatorError) {
      return response.json({
        'errors': [exception]
      }, statusCode: HttpStatus.badRequest);
    }
    return response.internalServerError(exception.toString());
  }
}
