part of '../tree/node.dart';

typedef Indexed<T> = ({int index, T value});

typedef IndexedValue<T> = Indexed<T>;

abstract interface class HandlerStore {
  IndexedValue? getHandler(HTTPMethod method);

  Iterable<HTTPMethod> get methods;

  bool hasMethod(HTTPMethod method);

  void addRoute<T>(HTTPMethod method, IndexedValue<T> handler);
  void addMiddleware<T>(IndexedValue<T> handler);
}

mixin HandlerStoreMixin implements HandlerStore {
  final Map<HTTPMethod, IndexedValue> requestHandlers = {};
  final List<IndexedValue> middlewares = [];

  @override
  Iterable<HTTPMethod> get methods => requestHandlers.keys;

  @override
  bool hasMethod(HTTPMethod method) => requestHandlers.containsKey(method);

  @override
  IndexedValue? getHandler(HTTPMethod method) =>
      requestHandlers[method] ?? requestHandlers[HTTPMethod.ALL];

  @override
  void addRoute<T>(HTTPMethod method, IndexedValue<T> handler) {
    if (requestHandlers.containsKey(method)) {
      final route = (this as Node).route;
      throw ArgumentError.value(
          '${method.name}: $route', null, 'Route entry already exists');
    }
    requestHandlers[method] = handler;
  }

  @override
  void addMiddleware<T>(IndexedValue<T> handler) {
    middlewares.add(handler);
  }
}
