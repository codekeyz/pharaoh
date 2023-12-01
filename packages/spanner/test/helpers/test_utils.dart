import 'package:spanner/src/tree_node.dart';
import 'package:test/expect.dart';

Matcher havingParameters(Map<String, dynamic> params) {
  return isA<Node>().having((p0) => p0.params, 'has parameters', params);
}

Matcher isStaticNode(String name) {
  return isA<Node>().having((p0) => p0.name, 'has name', 'static($name)');
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
