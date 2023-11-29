import 'package:pharaoh/pharaoh.dart';
import 'package:pharaoh_router/pharaoh_router.dart';
import 'package:test/test.dart';

void main() {
  // test('parametric route, parametric and suffixed', () {
  //   const config = RadixRouterConfig(caseSensitive: false);
  //   final router = RadixRouter(config: config)
  //     ..on(HTTPMethod.GET, '/:a')
  //     ..on(HTTPMethod.GET, '/:a.png');

  //   expect(router.lookup(HTTPMethod.GET, '/chima')?.value, {'a': 'chima'});
  //   expect(router.lookup(HTTPMethod.GET, '/dike.png')?.value, {'a': 'dike'});
  // });

  test('parametric route, request.url contains dash', () {
    final config = const RadixRouterConfig(caseSensitive: false);
    final router = RadixRouter(config: config)
      ..on(HTTPMethod.GET, '/a/:param/b');

    final result = router.lookup(HTTPMethod.GET, '/a/foo-bar/b');
    expect(result?.value, {'param': 'foo-bar'});
  });

  test('parametric route, and suffixed', () {
    const config = RadixRouterConfig(caseSensitive: false);
    final router = RadixRouter(config: config)
      ..on(HTTPMethod.POST, '/:file.png')
      ..on(HTTPMethod.GET, '/:image');

    expect(
      router.lookup(HTTPMethod.GET, '/hello.png')?.value,
      {'image': 'hello.png'},
    );

    expect(
      router.lookup(HTTPMethod.POST, '/a@b.c..png')?.value,
      {'file': 'a@b.c.'},
    );
  });

  test('parametric route with fixed suffix', () {
    final config = const RadixRouterConfig(caseSensitive: false);
    final router = RadixRouter(config: config)
      ..on(HTTPMethod.GET, '/a/:param-static')
      ..on(HTTPMethod.GET, '/b/:param.static');

    expect(router.lookup(HTTPMethod.GET, '/a/param-static')?.value,
        {'param': 'param'});
    expect(router.lookup(HTTPMethod.GET, '/b/param.static')?.value,
        {'param': 'param'});

    expect(router.lookup(HTTPMethod.GET, '/a/param-param-static')?.value,
        {'param': 'param-param'});
    expect(router.lookup(HTTPMethod.GET, '/b/param.param.static')?.value,
        {'param': 'param.param'});

    expect(router.lookup(HTTPMethod.GET, '/a/param.param-static')?.value,
        {'param': 'param.param'});
    expect(router.lookup(HTTPMethod.GET, '/b/param-param.static')?.value,
        {'param': 'param-param'});
  });
}
