import 'package:spanner/spanner.dart';
import 'package:spanner/src/parametric/definition.dart';
import 'package:spanner/src/tree/node.dart';
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
        router() => Spanner()..addRoute(HTTPMethod.GET, '/user/<userId><keyId>', null);

        final exception = runSyncAndReturnException<ArgumentError>(router);
        expect(exception.message,
            contains('Parameter definition is invalid. Close door neighbors'));
        expect(exception.invalidValue, '<userId><keyId>');
      });

      test('invalid parameter definition', () {
        router() =>
            Spanner()..addRoute(HTTPMethod.GET, '/user/<userId#@#.XDkd@#>>#>', null);

        final exception = runSyncAndReturnException<ArgumentError>(router);
        expect(exception.message, contains('Parameter definition is invalid'));
        expect(exception.invalidValue, '<userId#@#.XDkd@#>>#>');
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
        ..addRoute(HTTPMethod.GET, '/a/<param>-static', null)
        ..addRoute(HTTPMethod.GET, '/b/<param>.static', null);

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
          node, havingParameters<StaticNode>({'file': 'aws-image', 'user2': 'A29384'}));

      node = router.lookup(HTTPMethod.GET, '/a/param-static');
      expect(node, havingParameters<ParameterDefinition>({'param': 'param'}));

      node = router.lookup(HTTPMethod.GET, '/b/param.static');
      expect(node, havingParameters<ParameterDefinition>({'param': 'param'}));
    });

    test('contain param and wildcard together', () {
      final router = Spanner()
        ..addRoute(HTTPMethod.GET, '/<lang>/item/<id>', null)
        ..addRoute(HTTPMethod.GET, '/<lang>/item/*', null);

      expect(
        router.lookup(HTTPMethod.GET, '/fr/item/12345'),
        havingParameters({'lang': 'fr', 'id': '12345'}),
      );

      expect(
        router.lookup(HTTPMethod.GET, '/fr/item/12345/edit'),
        havingParameters({'lang': 'fr', '*': '12345/edit'}),
      );
    });

    test('should capture remaining parts as parameter when no wildcard', () {
      final router = Spanner()..addRoute(HTTPMethod.GET, '/<lang>/item/<id>', null);

      expect(
        router.lookup(HTTPMethod.GET, '/fr/item/12345'),
        havingParameters({'lang': 'fr', 'id': '12345'}),
      );

      expect(
        router.lookup(HTTPMethod.GET, '/fr/item/12345/edit'),
        havingParameters({'lang': 'fr', 'id': '12345/edit'}),
      );
    });

    group('when descriptors', () {
      test('in single parametric definition', () {
        final router = Spanner()
          ..addRoute(HTTPMethod.GET, '/users/<userId|(^\\w+)|number>/detail', null)
          ..addRoute(HTTPMethod.GET, '/<userId|(^\\w+)>', null);

        var result = router.lookup(HTTPMethod.GET, '/users/24/detail');
        expect(result, havingParameters({'userId': 24}));

        result = router.lookup(HTTPMethod.GET, '/hello-world');
        expect(result, havingParameters({'userId': 'hello-world'}));

        expect(
          runSyncAndReturnException(() => router.lookup(HTTPMethod.GET, '/@388>)#(***)')),
          isA<ArgumentError>()
              .having((p0) => p0.message, 'with message', 'Invalid parameter value'),
        );
      });

      test('in composite parametric definition', () async {
        final router = Spanner()
          ..addRoute(
              HTTPMethod.GET, '/users/<userId|number>HELLO<paramId|number>/detail', null);

        var result = router.lookup(HTTPMethod.GET, '/users/334HELLO387/detail');
        expect(result, havingParameters({'userId': 334, 'paramId': 387}));
      });
    });
  });
}
