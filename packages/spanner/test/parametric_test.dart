import 'package:pharaoh/pharaoh.dart';
import 'package:spanner/spanner.dart';
import 'package:test/test.dart';

import 'helpers/test_utils.dart';

void main() {
  group('parametric route', () {
    group('should reject', () {
      test('inconsistent parameter definitions', () {
        router() => RadixRouter()
          ..on(HTTPMethod.GET, '/user/<file>.png/download')
          ..on(HTTPMethod.GET, '/user/<hello>.png/<user2>/hello');

        final exception = runSyncAndReturnException<ArgumentError>(router);
        expect(exception.message,
            contains('Route has inconsistent name in parametric definition'));
        expect(exception.message, contains('<file>.png'));
        expect(exception.message, contains('<hello>.png'));
      });

      test('close door parameter definitions', () {
        router() => RadixRouter()..on(HTTPMethod.GET, '/user/<userId><keyId>');

        final exception = runSyncAndReturnException<ArgumentError>(router);
        expect(
            exception.message,
            contains(
                'Parameter definition is not valid. Close door neighbors'));
        expect(exception.invalidValue, '<userId><keyId>');
      });

      test('invalid parameter definition', () {
        router() => RadixRouter()
          ..on(HTTPMethod.GET, '/user/<userId#@#.XDkd@#>>#>', debug: true)
          ..printTree();

        final exception = runSyncAndReturnException<ArgumentError>(router);
        expect(
            exception.message, contains('Parameter definition is not valid'));
        expect(exception.invalidValue, '<userId#@#.XDkd@#>>#>');
      });
    });

    test('with request.url contains dash', () {
      final router = RadixRouter()..on(HTTPMethod.GET, '/a/<param>/b');
      final result = router.lookup(HTTPMethod.GET, '/a/foo-bar/b');
      expect(result, havingParameters({'param': 'foo-bar'}));
    });

    test('with fixed suffix', () async {
      final router = RadixRouter()
        ..on(HTTPMethod.GET, '/user')
        ..on(HTTPMethod.GET, '/user/<userId>')
        ..on(HTTPMethod.GET, '/user/<userId>/details')
        ..on(HTTPMethod.GET, '/user/<file>.png/download')
        ..on(HTTPMethod.GET, '/user/<file>.png/<user2>/hello')
        ..on(HTTPMethod.GET, '/a/<param>-static')
        ..on(HTTPMethod.GET, '/b/<param>.static');

      var node = router.lookup(HTTPMethod.GET, '/user');
      expect(node, isStaticNode('user'));

      node = router.lookup(HTTPMethod.GET, '/user/24');
      expect(node, havingParameters({'userId': '24'}));

      node = router.lookup(HTTPMethod.GET, '/user/3948/details');
      expect(node, havingParameters({'userId': '3948'}));

      node = router.lookup(HTTPMethod.GET, '/user/aws-image.png/download');
      expect(node, havingParameters({'file': 'aws-image'}));

      node = router.lookup(HTTPMethod.GET, '/user/aws-image.png/A29384/hello');
      expect(node, havingParameters({'file': 'aws-image', 'user2': 'A29384'}));

      node = router.lookup(HTTPMethod.GET, '/a/param-static');
      expect(node, havingParameters({'param': 'param'}));

      node = router.lookup(HTTPMethod.GET, '/b/param.static');
      expect(node, havingParameters({'param': 'param'}));
    });
  });
}
