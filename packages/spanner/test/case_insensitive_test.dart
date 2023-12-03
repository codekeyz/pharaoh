import 'package:pharaoh/pharaoh.dart';
import 'package:spanner/spanner.dart';
import 'package:spanner/src/parametric/definition.dart';
import 'package:spanner/src/tree/node.dart';
import 'package:test/test.dart';

import 'fixtures/handlers.dart';
import 'helpers/test_utils.dart';

void main() {
  test('case insensitive static routes of level 1', () {
    final config = const RouterConfig(caseSensitive: false);
    final router = Spanner(config: config)..on(HTTPMethod.GET, '/woo', okHdler);

    final result = router.lookup(HTTPMethod.GET, '/woo');
    expect(result, isStaticNode('woo'));
  });

  test('case insensitive static routes of level 2', () {
    final config = const RouterConfig(caseSensitive: false);
    final router = Spanner(config: config)
      ..on(HTTPMethod.GET, '/foo/woo', okHdler);

    final result = router.lookup(HTTPMethod.GET, '/foo/woo');
    expect(result, isStaticNode('woo'));
  });

  test('case insensitive static routes of level 3', () {
    final config = const RouterConfig(caseSensitive: false);
    final router = Spanner(config: config)
      ..on(HTTPMethod.GET, '/foo/bar/woo', okHdler);

    final node = router.lookup(HTTPMethod.GET, '/Foo/bAR/WoO');
    expect(node, isStaticNode('woo'));
  });

  test('parametric case insensitive', () {
    final config = const RouterConfig(caseSensitive: false);
    final router = Spanner(config: config)
      ..on(HTTPMethod.GET, '/foo/<param>', okHdler);

    expect(
      router.lookup(HTTPMethod.GET, '/Foo/bAR'),
      havingParameters<ParameterDefinition>({'param': 'bAR'}),
    );
  });

  test('parametric case insensitive with capital letter', () {
    final config = const RouterConfig(caseSensitive: false);
    final router = Spanner(config: config)
      ..on(HTTPMethod.GET, '/foo/<Param>', okHdler);

    expect(
      router.lookup(HTTPMethod.GET, '/Foo/bAR'),
      havingParameters<ParameterDefinition>({'Param': 'bAR'}),
    );
  });

  test('case insensitive with capital letter in static path with param', () {
    final config = const RouterConfig(caseSensitive: false);
    final router = Spanner(config: config)
      ..on(HTTPMethod.GET, '/Foo/bar/<param>', okHdler);

    expect(
      router.lookup(HTTPMethod.GET, '/foo/bar/baZ'),
      havingParameters<ParameterDefinition>({'param': 'baZ'}),
    );
  });

  test(
      'case insensitive with multiple paths containing capital letter in static path with param',
      () {
    final config = const RouterConfig(caseSensitive: false);
    final router = Spanner(config: config)
      ..on(HTTPMethod.GET, '/Foo/bar/<param>', okHdler)
      ..on(HTTPMethod.GET, '/Foo/baz/<param>', okHdler);

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
      ..on(HTTPMethod.GET, '/foo/<param1>/<param2>', okHdler);

    expect(
      router.lookup(HTTPMethod.GET, '/FOO/My/bAR'),
      havingParameters<ParameterDefinition>({'param1': 'My', 'param2': 'bAR'}),
    );
  });

  test('parametric case insensitive with multiple routes', () {
    final config = const RouterConfig(caseSensitive: false);
    final router = Spanner(config: config)
      ..on(HTTPMethod.POST, '/foo/<param>/Static/<userId>/Save', okHdler)
      ..on(HTTPMethod.POST, '/foo/<param>/Static/<userId>/Update', okHdler)
      ..on(HTTPMethod.POST, '/foo/<param>/Static/<userId>/CANCEL', okHdler);

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

  test(
      'case insensitive with multiple mixed-case params within same slash couple',
      () {
    final config = const RouterConfig(caseSensitive: false);
    final router = Spanner(config: config)
      ..on(HTTPMethod.GET, '/users/<userId>', okHdler)
      ..on(HTTPMethod.GET, '/users/user-<userId>.png<roomId>.dmg', okHdler)
      ..on(HTTPMethod.GET, '/foo/<param1>-<param2>', okHdler);

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
    final config = const RouterConfig(caseSensitive: false);
    final router = Spanner(config: config)
      ..on(HTTPMethod.GET, '/foo/my-<param>', okHdler);

    expect(
      router.lookup(HTTPMethod.GET, '/Foo/MY-bAR'),
      havingParameters({'param': 'bAR'}),
    );
  });
}
