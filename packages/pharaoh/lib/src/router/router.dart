import 'dart:async';

import 'package:pharaoh/pharaoh.dart';

import 'router_mixin.dart';

abstract class RoutePathDefinitionContract<T> {
  T get(String path, RequestHandlerFunc hdler);

  T post(String path, RequestHandlerFunc hdler);

  T put(String path, RequestHandlerFunc hdler);

  T delete(String path, RequestHandlerFunc hdler);

  T head(String path, RequestHandlerFunc hdler);

  T patch(String path, RequestHandlerFunc hdler);

  T options(String path, RequestHandlerFunc hdler);

  T trace(String path, RequestHandlerFunc hdler);

  T use(HandlerFunc mdw);

  T useOnPath(
    String path,
    HandlerFunc func, {
    HTTPMethod method = HTTPMethod.ALL,
  });
}

class PharaohRouter extends RoutePathDefinitionContract<PharaohRouter>
    with RouterMixin<PharaohRouter> {
  final List<ReqResHook> _preResponseHooks = [
    sessionPreResponseHook,
  ];

  Future<HandlerResult> resolve(Request req, Response res) async {
    ReqRes reqRes = (req: req, res: res);
    final routeResult = spanner.lookup(req.method, req.path);
    if (routeResult == null) {
      return (canNext: true, reqRes: reqRes);
    } else if (routeResult.handlers.isEmpty) {
      return (canNext: false, reqRes: reqRes);
    }

    routeResult.params.forEach((key, value) => req.setParams(key, value));

    reqRes = (req: req, res: res);

    bool canNext = false;
    for (final hdler in routeResult.handlers) {
      canNext = false;
      final result = await hdler.execute(reqRes);
      reqRes = result.reqRes;
      canNext = result.canNext;
      if (!canNext) break;
    }

    for (final job in _preResponseHooks) {
      reqRes = await Future.microtask(() => job(reqRes));
    }

    return (canNext: canNext, reqRes: reqRes);
  }
}
