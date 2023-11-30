import 'package:pharaoh_router/src/tree_node.dart';
import 'package:test/expect.dart';

Matcher havingParameters(Map<String, dynamic> params) {
  return isA<Node>().having((p0) => p0.params, 'has parameters', params);
}

Matcher hasStaticNode(String name) {
  return isA<Node>().having((p0) => p0.name, 'has name', 'static($name)');
}
