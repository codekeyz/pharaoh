import 'package:equatable/equatable.dart';
import 'package:pharaoh/pharaoh.dart';

typedef Indexed<T> = ({int index, T value});

typedef IndexedHandler = Indexed<HandlerFunc?>;

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

typedef MethodAndHandlerStore = Map<HTTPMethod, List<IndexedHandler>>;

mixin RouteActionMixin {
  final MethodAndHandlerStore store = {};

  Iterable<HTTPMethod> get methods => store.keys;

  bool hasMethod(HTTPMethod method) => store.containsKey(method);

  List<IndexedHandler> getActions(HTTPMethod method) {
    if (store.isEmpty) return [];

    final hdlersForMethod = store[method] ?? [];
    final allHandlers = store[HTTPMethod.ALL] ?? [];

    /// sorting is done to ensure we maintain the order in-which handlers were added.
    return [
      if (allHandlers.isNotEmpty) ...allHandlers,
      if (hdlersForMethod.isNotEmpty) ...hdlersForMethod,
    ]..sort((a, b) => a.index.compareTo(b.index));
  }

  void addHandler(HTTPMethod method, IndexedHandler hdlr) {
    final List<IndexedHandler> actionsList = store[method] ?? [];

    actionsList.add((index: hdlr.index, value: hdlr.value));
    store[method] = actionsList;
  }
}
