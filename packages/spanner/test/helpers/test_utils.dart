import 'package:spanner/spanner.dart';
import 'package:spanner/src/tree/node.dart';
import 'package:test/expect.dart';

Matcher havingParameters<T>(Map<String, dynamic> params) {
  return isA<RouteResult>()
      .having((p0) => p0.actual, 'with actual', isA<T>())
      .having((p0) => p0.params, 'with parameters', params);
}

Matcher isStaticNode(String name) {
  return isA<RouteResult>().having(
    (p0) => p0.actual,
    'has actual',
    isA<StaticNode>().having((p0) => p0.name, 'has name', name),
  );
}

Matcher hasValues<T>(List<T> result) {
  return isA<RouteResult>().having(
    (p0) => p0.values,
    'has values',
    result,
  );
}

T runSyncAndReturnException<T>(Function call) {
  dynamic result;
  try {
    call.call();
  } catch (e) {
    result = e;
  }

  expect(result, isA<T>());
  return result as T;
}
