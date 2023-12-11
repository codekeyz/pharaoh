import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http_parser/http_parser.dart';
import 'package:meta/meta.dart';
import 'package:spanner/spanner.dart';

import 'http/response.dart';
import 'http/response_impl.dart';
import 'http/request_impl.dart';
import 'middleware/session_mw.dart';
import 'router/_handler_executor.dart';
import 'router/router_contract.dart';
import 'router/router_handler.dart';
import 'router/router_mixin.dart';
import 'router/router.dart';
import 'view/view.dart';

import 'middleware/body_parser.dart';
import 'utils/exceptions.dart';
import 'shelf_interop/shelf.dart' as shelf;

part 'core_impl.dart';

abstract class Pharaoh implements RouterContract {
  factory Pharaoh() => $PharaohImpl();

  ViewEngine? get viewEngine;

  set viewEngine(ViewEngine? engine);

  RouterContract router();

  List<RouteEntry> get routes;

  String get routeStr;

  Uri get uri;

  Pharaoh group(String path, RouterContract router);

  Future<Pharaoh> listen({int port = 3000});

  @visibleForTesting
  void handleRequest(HttpRequest httpReq);

  Future<void> shutdown();
}
