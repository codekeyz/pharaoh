import '../tree/tree.dart';

typedef Indexed<T> = ({int index, T value});

typedef IndexedValue<T> = Indexed<T>;

mixin HandlerStore {
  final Map<HTTPMethod, IndexedValue> requestHandlers = {};

  final List<IndexedValue> middlewares = [];

  Iterable<HTTPMethod> get methods => requestHandlers.keys;

  bool hasMethod(HTTPMethod method) => requestHandlers.containsKey(method);

  IndexedValue? getHandler(HTTPMethod method) => requestHandlers[method];

  void addRoute<T>(HTTPMethod method, IndexedValue<T> handler) {
    if (method == HTTPMethod.ALL) {
      throw ArgumentError('HTTPMethod.all not supported for `addRoute`');
    }

    if (requestHandlers.containsKey(method)) {
      var name = (this as dynamic).name;
      throw ArgumentError.value(
          '${method.name}: $name', null, 'Route entry already exists');
    }

    requestHandlers[method] = handler;
  }

  void addMiddleware<T>(IndexedValue<T> handler) {
    middlewares.add(handler);
  }
}
