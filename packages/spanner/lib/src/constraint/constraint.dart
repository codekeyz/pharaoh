import 'package:equatable/equatable.dart';
import 'package:pharaoh/pharaoh.dart';

typedef RouteConstraint = ({
  String name,
  bool Function(Request request) hasMatch,
});

RouteConstraint httpMethodConstraint(HTTPMethod method) => (
      name: '__spanner_internal_strategy_http_method',
      hasMatch: (req) => method == HTTPMethod.ALL || req.method == method,
    );

extension RouteConstraintExtension on Iterable<RouteConstraint> {
  bool matches(Request request) => every((e) => e.hasMatch(request));
}

class RouteAction extends Equatable {
  final List<RouteConstraint> constraints;
  final RouteHandler handler;

  const RouteAction(this.handler, {this.constraints = const []});

  bool matches(Request request) =>
      constraints.isEmpty ? true : constraints.matches(request);

  @override
  List<Object?> get props => [handler, constraints];
}
