import 'package:equatable/equatable.dart';
import 'package:pharaoh/pharaoh.dart';

class RouteAction extends Equatable {
  final HTTPMethod method;
  final RouteHandler handler;

  const RouteAction(this.handler, {required this.method});

  bool matches(Request request) =>
      method == HTTPMethod.ALL || request.method == method;

  @override
  List<Object?> get props => [method];
}

mixin RouteActionMixin {
  final Map<HTTPMethod, List<RouteHandler>> _methodActionsMap = {};

  Iterable<HTTPMethod> get methods => _methodActionsMap.keys;

  bool hasMethod(HTTPMethod method) => _methodActionsMap.containsKey(method);

  List<RouteHandler> getActions(HTTPMethod method) =>
      _methodActionsMap[method] ?? [];

  void addAction(RouteAction action) {
    final method = action.method;
    final actionsList = _methodActionsMap[method] ?? [];
    actionsList.add(action.handler);
    _methodActionsMap[method] = actionsList;
  }
}
