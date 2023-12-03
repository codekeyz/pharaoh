import 'package:equatable/equatable.dart';
import 'package:pharaoh/pharaoh.dart';

class RouteAction extends Equatable {
  final HTTPMethod method;
  final RouteHandler handler;

  const RouteAction(this.handler, {required this.method});

  @override
  List<Object?> get props => [method];
}

typedef IndexedHandler = ({int index, RouteHandler hdler});

mixin RouteActionMixin {
  final Map<HTTPMethod, List<IndexedHandler>> methodActionsMap = {};

  Iterable<HTTPMethod> get methods => methodActionsMap.keys;

  bool hasMethod(HTTPMethod method) => methodActionsMap.containsKey(method);

  int _currentIndex = 0;

  List<RouteHandler> getActions(HTTPMethod method) {
    if (methodActionsMap.isEmpty) return [];

    final hdlersForMethod = methodActionsMap[method] ?? [];
    final allHandlers = methodActionsMap[HTTPMethod.ALL] ?? [];

    /// sorting is done to ensure we maintain the order in-which handlers
    /// where added.
    final result = [
      if (allHandlers.isNotEmpty) ...allHandlers,
      if (hdlersForMethod.isNotEmpty) ...hdlersForMethod,
    ]..sort((a, b) => a.index.compareTo(b.index));

    return result.map((e) => e.hdler).toList();
  }

  void addAction(RouteAction action) {
    final method = action.method;
    final actionsList = methodActionsMap[method] ?? [];
    actionsList.add((index: _currentIndex++, hdler: action.handler));
    methodActionsMap[method] = actionsList;
  }
}
