// ignore_for_file: avoid_function_literals_in_foreach_calls

part of '../core.dart';

class _PharaohNextImpl implements Application {
  late final AppConfig _appConfig;
  late final Spanner _spanner;

  ViewEngine? _viewEngine;

  _PharaohNextImpl(this._appConfig, this._spanner);

  @override
  T singleton<T extends Object>(T instance) => registerSingleton<T>(instance);

  @override
  T instanceOf<T extends Object>() => instanceFromRegistry<T>();

  @override
  void useRoutes(RoutesResolver routeResolver) {
    final routes = routeResolver.call();
    routes.forEach((route) => route.commit(_spanner));
  }

  @override
  void useViewEngine(ViewEngine viewEngine) => _viewEngine = viewEngine;

  @override
  AppConfig get config => _appConfig;

  @override
  String get name => config.name;

  @override
  String get url => config.url;

  @override
  int get port => config.port;

  Pharaoh _createPharaohInstance({OnErrorCallback? onException}) {
    final pharaoh = Pharaoh()
      ..useSpanner(_spanner)
      ..viewEngine = _viewEngine;
    if (onException != null) pharaoh.onError(onException);
    return pharaoh;
  }
}
