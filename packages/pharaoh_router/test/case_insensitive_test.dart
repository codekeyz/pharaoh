import 'package:pharaoh/pharaoh.dart';
import 'package:pharaoh_router/pharaoh_router.dart';
import 'package:test/test.dart';

void main() {
  test('case insensitive static routes of level 1', () {
    final config = const RadixRouterConfig(caseSensitive: false);
    final router = RadixRouter(config: config)..on(HTTPMethod.GET, '/woo');

    final result = router.lookup(HTTPMethod.GET, '/woo');
    expect(result, isNotNull);
  });

  test('case insensitive static routes of level 2', () {
    final config = const RadixRouterConfig(caseSensitive: false);
    final router = RadixRouter(config: config)..on(HTTPMethod.GET, '/foo/woo');

    final result = router.lookup(HTTPMethod.GET, '/foo/woo');
    expect(result, isNotNull);
  });

  test('case insensitive static routes of level 3', () {
    final config = const RadixRouterConfig(caseSensitive: false);
    final router = RadixRouter(config: config)
      ..on(HTTPMethod.GET, '/foo/bar/woo');

    final result = router.lookup(HTTPMethod.GET, '/Foo/bAR/WoO');
    expect(result, isNotNull);
  });

  test('parametric case insensitive', () {
    final config = const RadixRouterConfig(caseSensitive: false);
    final router = RadixRouter(config: config)
      ..on(HTTPMethod.GET, '/foo/:param');

    expect(
      router.lookup(HTTPMethod.GET, '/Foo/bAR')?.value,
      {'param': 'bAR'},
    );
  });

  test('parametric case insensitive with a static part', () {
    final config = const RadixRouterConfig(caseSensitive: false);
    final router = RadixRouter(config: config)
      ..on(HTTPMethod.GET, '/foo/my-:param');

    expect(
      router.lookup(HTTPMethod.GET, '/Foo/MY-bAR')?.value,
      {'param': 'bAR'},
    );
  });

  test('parametric case insensitive with capital letter', () {
    final config = const RadixRouterConfig(caseSensitive: false);
    final router = RadixRouter(config: config)
      ..on(HTTPMethod.GET, '/foo/:Param');

    expect(
      router.lookup(HTTPMethod.GET, '/Foo/bAR')?.value,
      {'Param': 'bAR'},
    );
  });

  test('case insensitive with capital letter in static path with param', () {
    final config = const RadixRouterConfig(caseSensitive: false);
    final router = RadixRouter(config: config)
      ..on(HTTPMethod.GET, '/Foo/bar/:param');

    expect(
      router.lookup(HTTPMethod.GET, '/foo/bar/baZ')?.value,
      {'param': 'baZ'},
    );
  });

  test(
      'case insensitive with multiple paths containing capital letter in static path with param',
      () {
    final config = const RadixRouterConfig(caseSensitive: false);
    final router = RadixRouter(config: config)
      ..on(HTTPMethod.GET, '/Foo/bar/:param')
      ..on(HTTPMethod.GET, '/Foo/baz/:param');

    expect(
      router.lookup(HTTPMethod.GET, '/foo/bar/baZ')?.value,
      {'param': 'baZ'},
    );
    expect(
      router.lookup(HTTPMethod.GET, '/foo/baz/baR')?.value,
      {'param': 'baR'},
    );
  });

  test(
      'case insensitive with multiple mixed-case params within same slash couple',
      () {
    final config = const RadixRouterConfig(caseSensitive: false);
    final router = RadixRouter(config: config)
      ..on(HTTPMethod.GET, '/foo/:param1-:param2');

    expect(
      router.lookup(HTTPMethod.GET, '/FOO/My-bAR')?.value,
      {'param1': 'My', 'param2': 'bAR'},
    );
  });

  test('case insensitive with multiple mixed-case params', () {
    final config = const RadixRouterConfig(caseSensitive: false);
    final router = RadixRouter(config: config)
      ..on(HTTPMethod.GET, '/foo/:param1/:param2');

    expect(
      router.lookup(HTTPMethod.GET, '/FOO/My/bAR')?.value,
      {'param1': 'My', 'param2': 'bAR'},
    );
  });

  test('parametric case insensitive with multiple routes', () {
    final config = const RadixRouterConfig(caseSensitive: false);
    final router = RadixRouter(config: config)
      ..on(HTTPMethod.POST, '/foo/:param/Static/:userId/Save')
      ..on(HTTPMethod.POST, '/foo/:param/Static/:userId/Update')
      ..on(HTTPMethod.POST, '/foo/:param/Static/:userId/CANCEL');

    expect(
      router.lookup(HTTPMethod.POST, '/foo/bAR/static/one/SAVE')?.value,
      {'param': 'bAR', 'userId': 'one'},
    );

    expect(
      router.lookup(HTTPMethod.POST, '/fOO/Bar/Static/two/update')?.value,
      {'param': 'Bar', 'userId': 'two'},
    );

    expect(
      router.lookup(HTTPMethod.POST, '/Foo/bAR/STATIC/THREE/cAnCeL')?.value,
      {'param': 'bAR', 'userId': 'THREE'},
    );
  });
}
