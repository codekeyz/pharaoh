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
  final List<IndexedValue> middlewares = [];
  final requestHandlers = List<IndexedValue?>.filled(
    HTTPMethod.values.length,
    null,
  );

  @override
  Iterable<HTTPMethod> get methods => HTTPMethod.values.where(hasMethod);

  @override
  bool hasMethod(HTTPMethod method) => requestHandlers[method.index] != null;

  @override
  IndexedValue? getHandler(HTTPMethod method) =>
      requestHandlers[method.index] ?? requestHandlers[HTTPMethod.ALL.index];

  @override
  void addRoute<T>(HTTPMethod method, IndexedValue<T> handler) {
    if (hasMethod(method)) {
      final route = (this as Node).route;
      throw ArgumentError.value(
          '${method.name}: $route', null, 'Route entry already exists');
    }
    requestHandlers[method.index] = handler;
  }

  @override
  void addMiddleware<T>(IndexedValue<T> handler) => middlewares.add(handler);
}
