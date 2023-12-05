import 'package:spanner/spanner.dart';
import '../http/request.dart';
import 'router_contract.dart';
import 'router_handler.dart';

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
