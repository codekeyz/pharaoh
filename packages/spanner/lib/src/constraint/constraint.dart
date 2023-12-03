import 'dart:async';

import 'package:pharaoh/pharaoh.dart';

typedef RouteConstraint = ({
  String name,
  FutureOr<bool> Function(Request request) matches,
});

RouteConstraint httpMethodConstraint(HTTPMethod method) => (
      name: '__spanner_internal_strategy_http_method',
      matches: (req) async {
        return method == HTTPMethod.ALL || req.method == method;
      }
    );
