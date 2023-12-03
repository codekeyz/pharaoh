import 'package:equatable/equatable.dart';
import 'package:pharaoh/pharaoh.dart';

typedef Indexed<T> = ({int index, T value});

typedef IndexedHandler = Indexed<RouteHandler>;

class RouteAction extends Equatable {
  final HTTPMethod method;
  final RouteHandler handler;
  final int index;

  const RouteAction(
    this.handler, {
    required this.method,
    required this.index,
  });

  @override
  List<Object?> get props => [method];
}

mixin RouteActionMixin {
  final Map<HTTPMethod, List<IndexedHandler>> methodActionsMap = {};

  Iterable<HTTPMethod> get methods => methodActionsMap.keys;

  bool hasMethod(HTTPMethod method) => methodActionsMap.containsKey(method);

  List<IndexedHandler> getActions(HTTPMethod method) {
    if (methodActionsMap.isEmpty) return [];

    final hdlersForMethod = methodActionsMap[method] ?? [];
    final allHandlers = methodActionsMap[HTTPMethod.ALL] ?? [];

    /// sorting is done to ensure we maintain the order in-which handlers
    /// where added.
    return [
      if (allHandlers.isNotEmpty) ...allHandlers,
      if (hdlersForMethod.isNotEmpty) ...hdlersForMethod,
    ]..sort((a, b) => a.index.compareTo(b.index));
  }

  void addAction(RouteAction action) {
    final method = action.method;
    final List<IndexedHandler> actionsList = methodActionsMap[method] ?? [];

    actionsList.add((index: action.index, value: action.handler));
    methodActionsMap[method] = actionsList;
  }
}
