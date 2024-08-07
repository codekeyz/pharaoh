import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http_parser/http_parser.dart';
import 'package:meta/meta.dart';
import 'package:spanner/spanner.dart';

import 'http/request.dart';
import 'http/response.dart';
import 'middleware/session_mw.dart';
import 'router/router_contract.dart';
import 'router/router_handler.dart';
import 'router/router_mixin.dart';
import 'router/router.dart';
import 'view/view.dart';

import 'middleware/body_parser.dart';
import 'utils/exceptions.dart';
import 'shelf_interop/shelf.dart' as shelf;

part 'core_impl.dart';

typedef PharaohError = ({Object exception, StackTrace trace});

typedef OnErrorCallback = FutureOr<Response> Function(
  PharaohError error,
  Request req,
  Response res,
);

abstract class Pharaoh implements RouterContract {
  static RouterContract get router => GroupRouter();

  factory Pharaoh() => $PharaohImpl();

  ViewEngine? get viewEngine;

  void onError(OnErrorCallback onError);

  set viewEngine(ViewEngine? engine);

  void useSpanner(Spanner spanner);

  Uri get uri;

  Pharaoh group(String path, RouterContract router);

  Future<Pharaoh> listen({int port = 3000});

  @visibleForTesting
  void handleRequest(HttpRequest httpReq);

  Future<void> shutdown();
}
