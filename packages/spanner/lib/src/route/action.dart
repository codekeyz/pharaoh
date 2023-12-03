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
  final Map<HTTPMethod, List<RouteHandler>> methodActionsMap = {};

  Iterable<HTTPMethod> get methods => methodActionsMap.keys;

  bool hasMethod(HTTPMethod method) => methodActionsMap.containsKey(method);

  List<RouteHandler> getActions(HTTPMethod method) =>
      methodActionsMap[method] ?? [];

  void addAction(RouteAction action) {
    final method = action.method;
    final actionsList = methodActionsMap[method] ?? [];
    actionsList.add(action.handler);
    methodActionsMap[method] = actionsList;
  }
}
