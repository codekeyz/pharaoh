import 'package:spanner/spanner.dart';
import 'package:spanner/src/parametric/definition.dart';
import 'package:spanner/src/tree/node.dart';
import 'package:test/test.dart';

import 'helpers/test_utils.dart';

void main() {
  test('case insensitive static routes of level 1', () {
    final config = const RouterConfig(caseSensitive: false);
    final router = Spanner(config: config)
      ..addRoute(HTTPMethod.GET, '/woo', 'Hello World');

    final result = router.lookup(HTTPMethod.GET, '/woo');
    expect(result, isStaticNode('woo'));
    expect(result, hasValues(['Hello World']));
  });

  test('case insensitive static routes of level 2', () {
    final config = const RouterConfig(caseSensitive: false);
    final router = Spanner(config: config)
      ..addRoute(HTTPMethod.GET, '/foo/woo', 'Foo Bar');

    final result = router.lookup(HTTPMethod.GET, '/foo/woo');
    expect(result, isStaticNode('woo'));
    expect(result, hasValues(['Foo Bar']));
  });

  test('case insensitive static routes of level 3', () {
    final config = const RouterConfig(caseSensitive: false);
    final router = Spanner(config: config)
      ..addRoute(HTTPMethod.GET, '/foo/bar/woo', 'foo bar');

    final result = router.lookup(HTTPMethod.GET, '/Foo/bAR/WoO');
    expect(result, isStaticNode('woo'));
    expect(result, hasValues(['foo bar']));
  });

  test('parametric case insensitive', () {
    final config = const RouterConfig(caseSensitive: false);
    final router = Spanner(config: config)
      ..addRoute(HTTPMethod.GET, '/foo/<param>', 'fam zing');

    final result = router.lookup(HTTPMethod.GET, '/Foo/bAR');
    expect(result, havingParameters<ParameterDefinition>({'param': 'bAR'}));
    expect(result, hasValues(['fam zing']));
  });

  test('parametric case insensitive with capital letter', () {
    final config = const RouterConfig(caseSensitive: false);
    final router = Spanner(config: config)
      ..addRoute(HTTPMethod.GET, '/foo/<Param>', 'on colos');

    final result = router.lookup(HTTPMethod.GET, '/Foo/bAR');
    expect(result, havingParameters<ParameterDefinition>({'Param': 'bAR'}));
    expect(result, hasValues(['on colos']));
  });

  test('case insensitive with capital letter in static path with param', () {
    final config = const RouterConfig(caseSensitive: false);
    final router = Spanner(config: config)
      ..addRoute(HTTPMethod.GET, '/Foo/bar/<param>', 'merry c');

    final result = router.lookup(HTTPMethod.GET, '/foo/bar/baZ');
    expect(result, havingParameters<ParameterDefinition>({'param': 'baZ'}));
    expect(result, hasValues(['merry c']));
  });

  test(
      'case insensitive with multiple paths containing capital letter in static path with param',
      () {
    final config = const RouterConfig(caseSensitive: false);
    final router = Spanner(config: config)
      ..addRoute(HTTPMethod.GET, '/Foo/bar/<param>', null)
      ..addRoute(HTTPMethod.GET, '/Foo/baz/<param>', null);

    expect(
      router.lookup(HTTPMethod.GET, '/foo/bar/baZ'),
      havingParameters<ParameterDefinition>({'param': 'baZ'}),
    );
    expect(
      router.lookup(HTTPMethod.GET, '/foo/baz/baR'),
      havingParameters<ParameterDefinition>({'param': 'baR'}),
    );
  });

  test('case insensitive with multiple mixed-case params', () {
    final config = const RouterConfig(caseSensitive: false);
    final router = Spanner(config: config)
      ..addRoute(HTTPMethod.GET, '/foo/<param1>/<param2>', null);

    expect(
      router.lookup(HTTPMethod.GET, '/FOO/My/bAR'),
      havingParameters<ParameterDefinition>({'param1': 'My', 'param2': 'bAR'}),
    );
  });

  test('parametric case insensitive with multiple routes', () {
    final config = const RouterConfig(caseSensitive: false);
    final router = Spanner(config: config)
      ..addRoute(HTTPMethod.POST, '/foo/<param>/Static/<userId>/Save', null)
      ..addRoute(HTTPMethod.POST, '/foo/<param>/Static/<userId>/Update', null)
      ..addRoute(HTTPMethod.POST, '/foo/<param>/Static/<userId>/CANCEL', null);

    expect(
      router.lookup(HTTPMethod.POST, '/foo/bAR/static/one/SAVE'),
      havingParameters({'param': 'bAR', 'userId': 'one'}),
    );

    expect(
      router.lookup(HTTPMethod.POST, '/fOO/Bar/Static/two/update'),
      havingParameters<StaticNode>({'param': 'Bar', 'userId': 'two'}),
    );

    expect(
      router.lookup(HTTPMethod.POST, '/Foo/bAR/STATIC/THREE/cAnCeL'),
      havingParameters<StaticNode>({'param': 'bAR', 'userId': 'THREE'}),
    );
  });

  test('case insensitive with multiple mixed-case params within same slash couple', () {
    final config = const RouterConfig(caseSensitive: false);
    final router = Spanner(config: config)
      ..addRoute(HTTPMethod.GET, '/users/<userId>', null)
      ..addRoute(HTTPMethod.GET, '/users/user-<userId>.png<roomId>.dmg', 'kanzo')
      ..addRoute(HTTPMethod.GET, '/foo/<param1>-<param2>', null);

    var result = router.lookup(HTTPMethod.GET, '/FOO/My-bAR');
    expect(result, havingParameters({'param1': 'My', 'param2': 'bAR'}));
    expect(result, hasValues([null]));

    result = router.lookup(HTTPMethod.GET, '/users/24');
    expect(result, havingParameters({'userId': '24'}));
    expect(result, hasValues([null]));

    result = router.lookup(HTTPMethod.GET, '/users/user-200.png234.dmg');
    expect(result, havingParameters({'userId': '200', 'roomId': '234'}));
    expect(result, hasValues(['kanzo']));
  });

  test('parametric case insensitive with a static part', () {
    final config = const RouterConfig(caseSensitive: false);
    final router = Spanner(config: config)
      ..addRoute(HTTPMethod.GET, '/foo/my-<param>', null);

    expect(
      router.lookup(HTTPMethod.GET, '/Foo/MY-bAR'),
      havingParameters({'param': 'bAR'}),
    );
  });
}
