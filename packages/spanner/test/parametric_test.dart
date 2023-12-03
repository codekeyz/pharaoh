import 'package:pharaoh/pharaoh.dart';
import 'package:spanner/spanner.dart';
import 'package:spanner/src/parametric/definition.dart';
import 'package:test/test.dart';

import 'fixtures/handlers.dart';
import 'helpers/test_utils.dart';

void main() {
  group('parametric route', () {
    group('should reject', () {
      test('inconsistent parameter definitions', () {
        router() => Spanner()
          ..on(HTTPMethod.GET, '/user/<file>.png/download', okHdler)
          ..on(HTTPMethod.POST, '/user/<heyyou>.png', okHdler)
          ..on(HTTPMethod.GET, '/user/<hello>.png/<user2>/hello', okHdler);

        final exception = runSyncAndReturnException<ArgumentError>(router);
        expect(exception.message,
            contains('Route has inconsistent naming in parameter definition'));
        expect(exception.message, contains('<file>.png'));
        expect(exception.message, contains('<hello>.png'));
      });

      test('close door parameter definitions', () {
        router() =>
            Spanner()..on(HTTPMethod.GET, '/user/<userId><keyId>', okHdler);

        final exception = runSyncAndReturnException<ArgumentError>(router);
        expect(
            exception.message,
            contains(
                'Parameter definition is not valid. Close door neighbors'));
        expect(exception.invalidValue, '<userId><keyId>');
      });

      test('invalid parameter definition', () {
        router() => Spanner()
          ..on(HTTPMethod.GET, '/user/<userId#@#.XDkd@#>>#>', okHdler);

        final exception = runSyncAndReturnException<ArgumentError>(router);
        expect(
            exception.message, contains('Parameter definition is not valid'));
        expect(exception.invalidValue, '<userId#@#.XDkd@#>>#>');
      });
    });

    test('with request.url contains dash', () {
      final router = Spanner()..on(HTTPMethod.GET, '/a/<param>/b', okHdler);

      final result = router.lookup(HTTPMethod.GET, '/a/foo-bar/b');
      expect(result, havingParameters<StaticNode>({'param': 'foo-bar'}));
    });

    test('with fixed suffix', () async {
      final router = Spanner()
        ..on(HTTPMethod.GET, '/user', okHdler)
        ..on(HTTPMethod.GET, '/user/<userId>', okHdler)
        ..on(HTTPMethod.GET, '/user/<userId>/details', okHdler)
        ..on(HTTPMethod.GET, '/user/<file>.png/download', okHdler)
        ..on(HTTPMethod.GET, '/user/<file>.png/<user2>/hello', okHdler)
        ..on(HTTPMethod.GET, '/a/<param>-static', okHdler)
        ..on(HTTPMethod.GET, '/b/<param>.static', okHdler);

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
      expect(node, havingParameters<ParameterDefinition>({'param': 'param'}));

      node = router.lookup(HTTPMethod.GET, '/b/param.static');
      expect(node, havingParameters<ParameterDefinition>({'param': 'param'}));
    });

    test('contain param and wildcard together', () {
      final router = Spanner()
        ..on(HTTPMethod.GET, '/<lang>/item/<id>', okHdler)
        ..on(HTTPMethod.GET, '/<lang>/item/*', okHdler);

      expect(
        router.lookup(HTTPMethod.GET, '/fr/item/12345'),
        havingParameters({'lang': 'fr', 'id': '12345'}),
      );

      expect(
        router.lookup(HTTPMethod.GET, '/fr/item/12345/edit'),
        havingParameters({'lang': 'fr', '*': '12345/edit'}),
      );
    });
  });
}
