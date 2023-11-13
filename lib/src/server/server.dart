import 'dart:async';

import '../router/handler.dart';
import '../router/route.dart';
import '../router/router.dart';
import 'server_impl.dart';

abstract class Pharaoh implements RoutePathDefinitionContract<Pharaoh> {
  factory Pharaoh() => $PharaohImpl();

  PharoahRouter router();

  List<Route> get routes;

  Uri get uri;

  void useOnPath(String path, RouteHandler handler);

  Future<Pharaoh> listen([int? port]);

  Future<void> shutdown();
}
