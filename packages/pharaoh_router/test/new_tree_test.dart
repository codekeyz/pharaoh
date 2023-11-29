import 'package:pharaoh/pharaoh.dart';
import 'package:pharaoh_router/pharaoh_router.dart';
import 'package:test/test.dart';

void main() {
  // test('parametric route, request.url contains dash', () {
  //   final config = const RadixRouterConfig(caseSensitive: false);
  //   final router = RadixRouter(config: config)
  //     ..on(HTTPMethod.GET, '/a/:param/b');

  //   final result = router.lookup(HTTPMethod.GET, '/a/foo-bar/b');
  //   expect(result?.value, {'param': 'foo-bar'});
  // });

  test('parametric route with fixed suffix', () async {
    final config = const RadixRouterConfig(caseSensitive: false);
    RadixRouter(config: config)
      ..addRoute(HTTPMethod.GET, '/user')
      ..addRoute(HTTPMethod.GET, '/user/:a')
      ..addRoute(HTTPMethod.GET, '/a/:param/b')
      ..addRoute(HTTPMethod.GET, '/:param-static/hello')
      ..addRoute(HTTPMethod.GET, '/home/come/here/:filename.png')
      ..printTree();
  });
}
