part of '../tree/node.dart';

typedef Indexed<T> = ({int index, T value});

typedef IndexedValue<T> = Indexed<T>;

abstract interface class HandlerStore<Owner extends Object> {
  IndexedValue? getHandler(HTTPMethod method);

  Iterable<HTTPMethod> get methods;

  void offsetIndex(int index);

  bool hasMethod(HTTPMethod method);

  void addRoute<T>(HTTPMethod method, IndexedValue<T> handler);
  void addMiddleware<T>(IndexedValue<T> handler);

  Owner get owner;
}

mixin HandlerStoreMixin implements HandlerStore {
  final List<IndexedValue> middlewares = [];
  final requestHandlers = List<IndexedValue?>.filled(
    HTTPMethod.values.length,
    null,
  );

  @override
  void offsetIndex(int index) {
    for (final middleware in middlewares.indexed) {
      middlewares[middleware.$1] = (
        index: middleware.$2.index + index,
        value: middleware.$2.value,
      );
    }

    // Offset the indices of request handlers
    for (int i = 0; i < requestHandlers.length; i++) {
      if (requestHandlers[i] != null) {
        requestHandlers[i] = (
          index: requestHandlers[i]!.index + index,
          value: requestHandlers[i]!.value,
        );
      }
    }
  }

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
