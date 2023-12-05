import 'dart:async';

import 'package:spanner/spanner.dart';

import '../http/request.dart';
import '../http/response.dart';
import '../middleware/session_mw.dart';
import 'router_contract.dart';
import 'router_handler.dart';
import 'router_mixin.dart';

class PharaohRouter extends RouterContract<PharaohRouter> with RouteDefinitionMixin {
  PharaohRouter(Spanner spanner) {
    useSpanner(spanner);
  }

  final List<ReqResHook> _preResponseHooks = [
    sessionPreResponseHook,
  ];

  Future<HandlerResult> resolve(Request req, Response res) async {
    ReqRes reqRes = (req: req, res: res);
    final _ = spanner.lookup(req.method, req.path);
    if (_ == null) {
      return (canNext: true, reqRes: reqRes);
    } else if (_.handlers.isEmpty) {
      return (canNext: true, reqRes: (req: req, res: res.notFound()));
    }

    _.params.forEach((key, value) => req.setParams(key, value));

    reqRes = (req: req, res: res);
    for (final hdler in _.handlers) {
      final result = await HandlerExecutor(hdler).execute(reqRes);
      reqRes = result.reqRes;
      if (!result.canNext || reqRes.res.ended) break;
    }

    for (final job in _preResponseHooks) {
      reqRes = await Future.microtask(() => job(reqRes));
    }

    if (!reqRes.res.ended) {
      return (
        canNext: true,
        reqRes: reqRes.merge(res.notFound("Route not found: ${req.path}"))
      );
    }

    return (canNext: true, reqRes: reqRes);
  }
}

typedef _PendingRouteIntent = (HTTPMethod method, ({String path, HandlerFunc handler}));

class GroupRouter extends RouterContract<GroupRouter> {
  final List<_PendingRouteIntent> _pendingRouteIntents = [];

  List<_PendingRouteIntent> get routes => _pendingRouteIntents;

  @override
  GroupRouter delete(String path, RequestHandlerFunc hdler) {
    _pendingRouteIntents.add((
      HTTPMethod.DELETE,
      (path: path, handler: useRequestHandler(hdler)),
    ));
    return this;
  }

  @override
  GroupRouter get(String path, RequestHandlerFunc hdler) {
    _pendingRouteIntents.add((
      HTTPMethod.GET,
      (path: path, handler: useRequestHandler(hdler)),
    ));
    return this;
  }

  @override
  GroupRouter head(String path, RequestHandlerFunc hdler) {
    _pendingRouteIntents.add((
      HTTPMethod.HEAD,
      (path: path, handler: useRequestHandler(hdler)),
    ));
    return this;
  }

  @override
  GroupRouter options(String path, RequestHandlerFunc hdler) {
    _pendingRouteIntents.add((
      HTTPMethod.OPTIONS,
      (path: path, handler: useRequestHandler(hdler)),
    ));
    return this;
  }

  @override
  GroupRouter patch(String path, RequestHandlerFunc hdler) {
    _pendingRouteIntents.add((
      HTTPMethod.PATCH,
      (path: path, handler: useRequestHandler(hdler)),
    ));
    return this;
  }

  @override
  GroupRouter post(String path, RequestHandlerFunc hdler) {
    _pendingRouteIntents.add((
      HTTPMethod.POST,
      (path: path, handler: useRequestHandler(hdler)),
    ));
    return this;
  }

  @override
  GroupRouter put(String path, RequestHandlerFunc hdler) {
    _pendingRouteIntents.add((
      HTTPMethod.PUT,
      (path: path, handler: useRequestHandler(hdler)),
    ));
    return this;
  }

  @override
  GroupRouter trace(String path, RequestHandlerFunc hdler) {
    _pendingRouteIntents.add((
      HTTPMethod.TRACE,
      (path: path, handler: useRequestHandler(hdler)),
    ));
    return this;
  }

  @override
  GroupRouter use(HandlerFunc mdw) {
    _pendingRouteIntents.add((HTTPMethod.ALL, (path: '/*', handler: mdw)));
    return this;
  }

  @override
  GroupRouter useOnPath(
    String path,
    HandlerFunc func, {
    HTTPMethod method = HTTPMethod.ALL,
  }) {
    _pendingRouteIntents.add((method, (path: '$path/*', handler: func)));
    return this;
  }

  void commit(String prefix, Spanner spanner) {
    for (final intent in _pendingRouteIntents) {
      final handler = intent.$2.handler;
      final path = intent.$2.path;
      spanner.on(intent.$1, '$prefix$path', handler);
    }
  }
}
