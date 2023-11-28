import 'package:pharaoh/pharaoh.dart';
import 'package:pharaoh_router/src/tree_router.dart';
import 'package:test/test.dart';

void main() {
  test('wildcard_test', () {
    const config = RadixRouterConfig(caseSensitive: false);
    final router = RadixRouter(config: config)
      ..on(HTTPMethod.GET, '/:file(^\\S+).png');

    router.printTree();
  });
}
