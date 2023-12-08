import 'controller.dart';

abstract class AppModule {
  final List<BaseController> controllers;
  final List<Middleware> middlewares;

  AppModule({
    this.controllers = const [],
    this.middlewares = const [],
  });
}
