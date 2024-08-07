import 'package:spanner/src/parametric/definition.dart';
import 'package:spanner/src/tree/node.dart';
import 'package:spanner/src/tree/tree.dart';
import 'package:test/test.dart';

import 'helpers/test_utils.dart';

void main() {
  group('parametric route', () {
    group('should reject', () {
      test('inconsistent parameter definitions', () {
        router() => Spanner()
          ..addRoute(HTTPMethod.GET, '/user/<file>.png/download', null)
          ..addRoute(HTTPMethod.POST, '/user/<heyyou>.png', null)
          ..addRoute(HTTPMethod.GET, '/user/<hello>.png/<user2>/hello', null);

        final exception = runSyncAndReturnException<ArgumentError>(router);
        expect(exception.message,
            contains('Route has inconsistent naming in parameter definition'));
        expect(exception.message, contains('<file>.png'));
        expect(exception.message, contains('<hello>.png'));
      });

      test('close door parameter definitions', () {
        router() =>
            Spanner()..addRoute(HTTPMethod.GET, '/user/<userId><keyId>', null);

        final exception = runSyncAndReturnException<ArgumentError>(router);
        expect(exception.message,
            contains('Parameter definition is invalid. Close door neighbors'));
        expect(exception.invalidValue, '<userId><keyId>');
      });

      test('invalid parameter definition', () {
        router() => Spanner()
          ..addRoute(HTTPMethod.GET, '/user/<userId#@#.XDkd@#>>#>', null);

        final exception = runSyncAndReturnException<ArgumentError>(router);
        expect(exception.message, contains('Parameter definition is invalid'));
        expect(exception.invalidValue, '<userId#@#.XDkd@#>>#>');
      });

      test('duplicate routes', () {
        router() => Spanner()
          ..addRoute(HTTPMethod.GET, '/user', null)
          ..addRoute(HTTPMethod.GET, '/user', null);

        router2() => Spanner()
          ..addRoute(HTTPMethod.GET, '/<lang>/item/<id>', null)
          ..addRoute(HTTPMethod.GET, '/<lang>/item/<id>', null);

        router3() => Spanner()
          ..addRoute(HTTPMethod.GET, '/<lang>/item/chima<id>hello', null)
          ..addRoute(HTTPMethod.GET, '/<lang>/item/chima<id>hello', null);

        var exception = runSyncAndReturnException<ArgumentError>(router);
        expect(exception.message, contains('Route entry already exists'));

        exception = runSyncAndReturnException<ArgumentError>(router2);
        expect(exception.message, contains('Route entry already exists'));

        exception = runSyncAndReturnException<ArgumentError>(router3);
        expect(exception.message, contains('Route entry already exists'));
      });
    });

    test('with request.url contains dash', () {
      final router = Spanner()..addRoute(HTTPMethod.GET, '/a/<param>/b', null);

      final result = router.lookup(HTTPMethod.GET, '/a/foo-bar/b');
      expect(result, havingParameters<StaticNode>({'param': 'foo-bar'}));
    });

    test('with fixed suffix', () async {
      final router = Spanner()
        ..addRoute(HTTPMethod.GET, '/user', null)
        ..addRoute(HTTPMethod.GET, '/user/<userId>', null)
        ..addRoute(HTTPMethod.GET, '/user/<userId>/details', null)
        ..addRoute(HTTPMethod.GET, '/user/<file>.png/download', null)
        ..addRoute(HTTPMethod.GET, '/user/<file>.png/<user2>/hello', null)
        ..addRoute(HTTPMethod.GET, '/a/<userId>-static', null)
        ..addRoute(HTTPMethod.GET, '/b/<userId>.static', null);

      var node = router.lookup(HTTPMethod.GET, '/user');
      expect(node, isStaticNode('user'));

      node = router.lookup(HTTPMethod.GET, '/user/24');
      expect(node, havingParameters<ParameterDefinition>({'userId': '24'}));

      node = router.lookup(HTTPMethod.GET, '/user/3948/details');
      expect(node, havingParameters<StaticNode>({'userId': '3948'}));

      node = router.lookup(HTTPMethod.GET, '/user/aws-image.png/download');
      expect(node, havingParameters<StaticNode>({'file': 'aws-image'}));

      node = router.lookup(HTTPMethod.GET, '/user/aws-image.png/A29384/hello');
      expect(
          node,
          havingParameters<StaticNode>(
              {'file': 'aws-image', 'user2': 'A29384'}));

      node = router.lookup(HTTPMethod.GET, '/a/param-static');
      expect(node, havingParameters<ParameterDefinition>({'userId': 'param'}));

      node = router.lookup(HTTPMethod.GET, '/b/param.static');
      expect(node, havingParameters<ParameterDefinition>({'userId': 'param'}));
    });

    test('contain param and wildcard together', () {
      final router = Spanner()
        ..addRoute(HTTPMethod.GET, '/<lang>/item/<id>', null)
        ..addRoute(HTTPMethod.GET, '/<lang>/item/*', #wild);

      expect(
        router.lookup(HTTPMethod.GET, '/fr/item/12345'),
        havingParameters({'lang': 'fr', 'id': '12345'}),
      );

      final result = router.lookup(HTTPMethod.GET, '/fr/item/12345/edit');
      expect(result?.values, [#wild]);
      expect(result?.params, {'lang': 'fr', 'id': '12345'});
    });
  });
}
