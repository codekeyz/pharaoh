import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:meta/meta.dart';

import './router/router.dart';
import './router/handler.dart';
import './http/request.dart';
import './http/response.dart';
import './middleware/body_parser.dart';
import './shelf_interop/shelf.dart' as shelf;
import 'router/router_mixin.dart';

part 'core_impl.dart';

abstract class Pharaoh implements RoutePathDefinitionContract<Pharaoh> {
  factory Pharaoh() => _$PharaohImpl();

  RoutePathDefinitionContract router();

  List<dynamic> get routes;

  Uri get uri;

  Pharaoh group(String path, RouteHandler handler);

  Future<Pharaoh> listen({int port = 3000});

  @visibleForTesting
  void handleRequest(HttpRequest httpReq);

  Future<void> shutdown();
}
