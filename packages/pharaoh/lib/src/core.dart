import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:meta/meta.dart';
import 'package:spanner/spanner.dart';

import 'middleware/session_mw.dart';
import 'router/router_contract.dart';
import 'router/router_handler.dart';
import 'router/router_mixin.dart';
import 'router/router.dart';

import 'http/response.dart';
import 'http/request.dart';

import 'middleware/body_parser.dart';
import 'utils/exceptions.dart';
import 'shelf_interop/shelf.dart' as shelf;

part 'core_impl.dart';

abstract class Pharaoh implements RouterContract<Pharaoh> {
  factory Pharaoh() => _$PharaohImpl();

  RouterContract<GroupRouter> router();

  List<dynamic> get routes;

  Uri get uri;

  Pharaoh group(String path, RouterContract<GroupRouter> router);

  Future<Pharaoh> listen({int port = 3000});

  @visibleForTesting
  void handleRequest(HttpRequest httpReq);

  Future<void> shutdown();
}
