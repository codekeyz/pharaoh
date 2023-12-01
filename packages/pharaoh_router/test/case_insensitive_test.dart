import 'package:pharaoh/pharaoh.dart';
import 'package:pharaoh_router/pharaoh_router.dart';
import 'package:test/test.dart';

import 'helpers/matchers.dart';

void main() {
  test('case insensitive static routes of level 1', () {
    final config = const RadixRouterConfig(caseSensitive: false);
    final router = RadixRouter(config: config)..on(HTTPMethod.GET, '/woo');

    final result = router.lookup(HTTPMethod.GET, '/woo');
    expect(result, isStaticNode('woo'));
  });

  test('case insensitive static routes of level 2', () {
    final config = const RadixRouterConfig(caseSensitive: false);
    final router = RadixRouter(config: config)..on(HTTPMethod.GET, '/foo/woo');

    final result = router.lookup(HTTPMethod.GET, '/foo/woo');
    expect(result, isStaticNode('woo'));
  });

  test('case insensitive static routes of level 3', () {
    final config = const RadixRouterConfig(caseSensitive: false);
    final router = RadixRouter(config: config)
      ..on(HTTPMethod.GET, '/foo/bar/woo');

    final node = router.lookup(HTTPMethod.GET, '/Foo/bAR/WoO');
    expect(node, isStaticNode('woo'));
  });

  test('parametric case insensitive', () {
    final config = const RadixRouterConfig(caseSensitive: false);
    final router = RadixRouter(config: config)
      ..on(HTTPMethod.GET, '/foo/<param>');

    expect(
      router.lookup(HTTPMethod.GET, '/Foo/bAR'),
      havingParameters({'param': 'bAR'}),
    );
  });

  test('parametric case insensitive with capital letter', () {
    final config = const RadixRouterConfig(caseSensitive: false);
    final router = RadixRouter(config: config)
      ..on(HTTPMethod.GET, '/foo/<Param>');

    expect(
      router.lookup(HTTPMethod.GET, '/Foo/bAR'),
      havingParameters({'Param': 'bAR'}),
    );
  });

  test('case insensitive with capital letter in static path with param', () {
    final config = const RadixRouterConfig(caseSensitive: false);
    final router = RadixRouter(config: config)
      ..on(HTTPMethod.GET, '/Foo/bar/<param>');

    expect(
      router.lookup(HTTPMethod.GET, '/foo/bar/baZ'),
      havingParameters({'param': 'baZ'}),
    );
  });

  test(
      'case insensitive with multiple paths containing capital letter in static path with param',
      () {
    final config = const RadixRouterConfig(caseSensitive: false);
    final router = RadixRouter(config: config)
      ..on(HTTPMethod.GET, '/Foo/bar/<param>')
      ..on(HTTPMethod.GET, '/Foo/baz/<param>');

    expect(
      router.lookup(HTTPMethod.GET, '/foo/bar/baZ'),
      havingParameters({'param': 'baZ'}),
    );
    expect(
      router.lookup(HTTPMethod.GET, '/foo/baz/baR'),
      havingParameters({'param': 'baR'}),
    );
  });

  test('case insensitive with multiple mixed-case params', () {
    final config = const RadixRouterConfig(caseSensitive: false);
    final router = RadixRouter(config: config)
      ..on(HTTPMethod.GET, '/foo/<param1>/<param2>');

    expect(
      router.lookup(HTTPMethod.GET, '/FOO/My/bAR'),
      havingParameters({'param1': 'My', 'param2': 'bAR'}),
    );
  });

  test('parametric case insensitive with multiple routes', () {
    final config = const RadixRouterConfig(caseSensitive: false);
    final router = RadixRouter(config: config)
      ..on(HTTPMethod.POST, '/foo/<param>/Static/<userId>/Save')
      ..on(HTTPMethod.POST, '/foo/<param>/Static/<userId>/Update')
      ..on(HTTPMethod.POST, '/foo/<param>/Static/<userId>/CANCEL');

    expect(
      router.lookup(HTTPMethod.POST, '/foo/bAR/static/one/SAVE'),
      havingParameters({'param': 'bAR', 'userId': 'one'}),
    );

    expect(
      router.lookup(HTTPMethod.POST, '/fOO/Bar/Static/two/update'),
      havingParameters({'param': 'Bar', 'userId': 'two'}),
    );

    expect(
      router.lookup(HTTPMethod.POST, '/Foo/bAR/STATIC/THREE/cAnCeL'),
      havingParameters({'param': 'bAR', 'userId': 'THREE'}),
    );
  });

  test(
      'case insensitive with multiple mixed-case params within same slash couple',
      () {
    final config = const RadixRouterConfig(caseSensitive: false);
    final router = RadixRouter(config: config)
      ..on(HTTPMethod.GET, '/users/<userId>')
      ..on(HTTPMethod.GET, '/users/user-<userId>.png<roomId>.dmg')
      ..on(HTTPMethod.GET, '/foo/<param1>-<param2>');

    expect(
      router.lookup(HTTPMethod.GET, '/FOO/My-bAR'),
      havingParameters({'param1': 'My', 'param2': 'bAR'}),
    );

    expect(
      router.lookup(HTTPMethod.GET, '/users/24'),
      havingParameters({'userId': '24'}),
    );

    expect(
      router.lookup(HTTPMethod.GET, '/users/user-200.png234.dmg'),
      havingParameters({'userId': '200', 'roomId': '234'}),
    );
  });

  test('parametric case insensitive with a static part', () {
    final config = const RadixRouterConfig(caseSensitive: false);
    final router = RadixRouter(config: config)
      ..on(HTTPMethod.GET, '/foo/my-<param>');

    expect(
      router.lookup(HTTPMethod.GET, '/Foo/MY-bAR'),
      havingParameters({'param': 'bAR'}),
    );
  });
}
