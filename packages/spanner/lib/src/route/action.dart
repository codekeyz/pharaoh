part of '../tree/node.dart';

typedef Indexed<T> = ({int index, T value});

typedef IndexedValue<T> = Indexed<T>;

mixin HandlerStore {
  final Map<HTTPMethod, IndexedValue> requestHandlers = {};

  final List<IndexedValue> middlewares = [];

  Iterable<HTTPMethod> get methods => requestHandlers.keys;

  bool hasMethod(HTTPMethod method) => requestHandlers.containsKey(method);

  IndexedValue? getHandler(HTTPMethod method) => requestHandlers[method];

  void addRoute<T>(HTTPMethod method, IndexedValue<T> handler) {
    if (requestHandlers.containsKey(method)) {
      final route = (this as Node).route;
      throw ArgumentError.value(
          '${method.name}: $route', null, 'Route entry already exists');
    }
    requestHandlers[method] = handler;
  }

  void addMiddleware<T>(IndexedValue<T> handler) {
    middlewares.add(handler);
  }
}
