import 'package:pharaoh/pharaoh.dart';
import 'package:pharaoh_router/pharaoh_router.dart';
import 'package:test/test.dart';

void main() {
  test('case insensitive static routes of level 1', () {
    final router = RadixRouter()..insert(HTTPMethod.GET, '/woo');
    final result = router.lookup(HTTPMethod.GET, '/woo');
    expect(result, isNotNull);
  });

  test('case insensitive static routes of level 2', () {
    final router = RadixRouter()..insert(HTTPMethod.GET, '/foo/woo');
    final result = router.lookup(HTTPMethod.GET, '/foo/woo');
    expect(result, isNotNull);
  });

  test('case insensitive static routes of level 3', () {
    final router = RadixRouter()..insert(HTTPMethod.GET, '/foo/bar/woo');
    final result = router.lookup(HTTPMethod.GET, '/Foo/bAR/WoO');
    expect(result, isNotNull);
  });

  test('parametric case insensitive', () {
    final router = RadixRouter()..insert(HTTPMethod.GET, '/foo/:param');
    expect(router.lookup(HTTPMethod.GET, '/Foo/bAR')?.value, {'param': 'bAR'});
  });

  test('parametric case insensitive with a static part', () {
    final router = RadixRouter()..insert(HTTPMethod.GET, '/foo/my-:param');
    expect(
      router.lookup(HTTPMethod.GET, '/Foo/MY-bAR')?.value,
      {'param': 'bAR'},
    );
  });

  test('parametric case insensitive with capital letter', () {
    final router = RadixRouter()..insert(HTTPMethod.GET, '/foo/:Param');
    expect(
      router.lookup(HTTPMethod.GET, '/Foo/bAR')?.value,
      {'Param': 'bAR'},
    );
  });

  test('case insensitive with capital letter in static path with param', () {
    final router = RadixRouter()..insert(HTTPMethod.GET, '/Foo/bar/:param');
    expect(
      router.lookup(HTTPMethod.GET, '/foo/bar/baZ')?.value,
      {'param': 'baZ'},
    );
  });

  test(
      'case insensitive with multiple paths containing capital letter in static path with param',
      () {
    final router = RadixRouter()
      ..insert(HTTPMethod.GET, '/Foo/bar/:param')
      ..insert(HTTPMethod.GET, '/Foo/baz/:param');

    expect(
      router.lookup(HTTPMethod.GET, '/foo/bar/baZ')?.value,
      {'param': 'baZ'},
    );
    expect(
      router.lookup(HTTPMethod.GET, '/foo/baz/baR')?.value,
      {'param': 'baR'},
    );
  });

  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///

  test('parametric route, request.url contains dash', () {
    final router = RadixRouter()..insert(HTTPMethod.GET, '/a/:param/b');
    final result = router.lookup(HTTPMethod.GET, '/a/foo-bar/b');
    expect(result!.value, {'param': 'foo-bar'});
  });

  test('parametric route with fixed suffix', () {
    final router = RadixRouter()
      ..insert(HTTPMethod.GET, '/a/:param-static')
      ..insert(HTTPMethod.GET, '/b/:param.static');

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
