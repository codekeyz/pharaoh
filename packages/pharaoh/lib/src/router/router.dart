import 'package:spanner/spanner.dart';

import 'router_contract.dart';
import 'router_handler.dart';

typedef _PendingRouteIntent = (HTTPMethod method, ({String path, Middleware handler}));

class GroupRouter extends RouterContract {
  final List<_PendingRouteIntent> _pendingRouteIntents = [];

  List<_PendingRouteIntent> get routes => _pendingRouteIntents;

  @override
  GroupRouter delete(String path, RequestHandler hdler) {
    _pendingRouteIntents.add((
      HTTPMethod.DELETE,
      (path: path, handler: useRequestHandler(hdler)),
    ));
    return this;
  }

  @override
  GroupRouter get(String path, RequestHandler hdler) {
    _pendingRouteIntents.add((
      HTTPMethod.GET,
      (path: path, handler: useRequestHandler(hdler)),
    ));
    return this;
  }

  @override
  GroupRouter head(String path, RequestHandler hdler) {
    _pendingRouteIntents.add((
      HTTPMethod.HEAD,
      (path: path, handler: useRequestHandler(hdler)),
    ));
    return this;
  }

  @override
  GroupRouter options(String path, RequestHandler hdler) {
    _pendingRouteIntents.add((
      HTTPMethod.OPTIONS,
      (path: path, handler: useRequestHandler(hdler)),
    ));
    return this;
  }

  @override
  GroupRouter patch(String path, RequestHandler hdler) {
    _pendingRouteIntents.add((
      HTTPMethod.PATCH,
      (path: path, handler: useRequestHandler(hdler)),
    ));
    return this;
  }

  @override
  GroupRouter post(String path, RequestHandler hdler) {
    _pendingRouteIntents.add((
      HTTPMethod.POST,
      (path: path, handler: useRequestHandler(hdler)),
    ));
    return this;
  }

  @override
  GroupRouter put(String path, RequestHandler hdler) {
    _pendingRouteIntents.add((
      HTTPMethod.PUT,
      (path: path, handler: useRequestHandler(hdler)),
    ));
    return this;
  }

  @override
  GroupRouter trace(String path, RequestHandler hdler) {
    _pendingRouteIntents.add((
      HTTPMethod.TRACE,
      (path: path, handler: useRequestHandler(hdler)),
    ));
    return this;
  }

  @override
  GroupRouter use(Middleware mdw) {
    _pendingRouteIntents.add((HTTPMethod.ALL, (path: '*', handler: mdw)));
    return this;
  }

  @override
  GroupRouter on(String path, Middleware func, {HTTPMethod method = HTTPMethod.ALL}) {
    if (method == HTTPMethod.ALL) path = '$path/*';
    _pendingRouteIntents.add((method, (path: path, handler: func)));
    return this;
  }

  void commit(String prefix, Spanner spanner) {
    for (final intent in _pendingRouteIntents) {
      final handler = intent.$2.handler;
      if (intent.$1 == HTTPMethod.ALL) {
        spanner.addMiddleware(prefix, handler);
      } else {
        spanner.addRoute(intent.$1, '$prefix${intent.$2.path}', handler);
      }
    }
  }
}
