import 'package:equatable/equatable.dart';
import 'package:pharaoh/pharaoh.dart';

typedef Indexed<T> = ({int index, T value});

typedef IndexedHandler = Indexed<HandlerFunc>;

class RouteAction extends Equatable {
  final HTTPMethod method;
  final HandlerFunc handler;
  final int index;

  const RouteAction(
    this.handler, {
    required this.method,
    required this.index,
  });

  @override
  List<Object?> get props => [method];
}

mixin HandlerStore {
  final Map<HTTPMethod, IndexedHandler> requestHandlers = {};

  final List<IndexedHandler> middlewares = [];

  Iterable<HTTPMethod> get methods => requestHandlers.keys;

  bool hasMethod(HTTPMethod method) => requestHandlers.containsKey(method);

  IndexedHandler? getHandler(HTTPMethod method) => requestHandlers[method];

  void addRoute(HTTPMethod method, IndexedHandler handler) {
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

  void addMiddleware(IndexedHandler handler) {
    middlewares.add(handler);
  }
}
