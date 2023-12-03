import 'dart:async';

import 'package:pharaoh/src/middleware/session_mw.dart';
import 'package:spanner/spanner.dart';
import '../http/request.dart';
import '../http/response.dart';
import 'handler.dart';

abstract interface class RoutePathDefinitionContract<T> {
  T get(String path, RequestHandlerFunc hdler);

  T post(String path, RequestHandlerFunc hdler);

  T put(String path, RequestHandlerFunc hdler);

  T delete(String path, RequestHandlerFunc hdler);

  T head(String path, RequestHandlerFunc hdler);

  T patch(String path, RequestHandlerFunc hdler);

  T options(String path, RequestHandlerFunc hdler);

  T trace(String path, RequestHandlerFunc hdler);

  T use(HandlerFunc mdw, {String? onpath});
}

class PharaohRouter implements RoutePathDefinitionContract<PharaohRouter> {
  final Router _router = Router();
  final List<ReqResHook> _preResponseHooks = [
    sessionPreResponseHook,
  ];

  @override
  PharaohRouter delete(String path, RequestHandlerFunc hdler) {
    _router.on(HTTPMethod.DELETE, path, RequestHandler(hdler));
    return this;
  }

  @override
  PharaohRouter get(String path, RequestHandlerFunc hdler) {
    _router.on(HTTPMethod.GET, path, RequestHandler(hdler));
    _router.on(HTTPMethod.HEAD, path, RequestHandler(hdler));
    return this;
  }

  @override
  PharaohRouter head(String path, RequestHandlerFunc hdler) {
    _router.on(HTTPMethod.HEAD, path, RequestHandler(hdler));
    return this;
  }

  @override
  PharaohRouter options(String path, RequestHandlerFunc hdler) {
    _router.on(HTTPMethod.OPTIONS, path, RequestHandler(hdler));
    return this;
  }

  @override
  PharaohRouter patch(String path, RequestHandlerFunc hdler) {
    _router.on(HTTPMethod.PATCH, path, RequestHandler(hdler));
    return this;
  }

  @override
  PharaohRouter post(String path, RequestHandlerFunc hdler) {
    _router.on(HTTPMethod.POST, path, RequestHandler(hdler));
    return this;
  }

  @override
  PharaohRouter put(String path, RequestHandlerFunc hdler) {
    _router.on(HTTPMethod.PUT, path, RequestHandler(hdler));
    return this;
  }

  @override
  PharaohRouter trace(String path, RequestHandlerFunc hdler) {
    _router.on(HTTPMethod.TRACE, path, RequestHandler(hdler));
    return this;
  }

  Future<HandlerResult> resolve(Request req, Response res) async {
    final _ = await _router.resolve(req, res);
    final canNext = _?.canNext ?? false;
    var reqRes = _?.reqRes ?? (req: req, res: res);
    if (_ != null) {
      for (final job in _preResponseHooks) {
        reqRes = await Future.microtask(() => job(reqRes));
      }
    }
    return (canNext: canNext, reqRes: reqRes);
  }

  @override
  PharaohRouter use(HandlerFunc mdw, {String? onpath}) {
    return this;
  }
}
