import 'package:pharaoh/pharaoh.dart';
import 'package:pharaoh_router/pharaoh_router.dart';
import 'package:test/test.dart';

import 'helpers/matchers.dart';

void main() {
  group('parametric route', () {
    group('should reject', () {
      test('inconsistent parametric definitions', () {
        final config = const RadixRouterConfig(caseSensitive: false);

        bool exceptionThrown = false;

        try {
          RadixRouter(config: config)
            ..on(HTTPMethod.GET, '/user')
            ..on(HTTPMethod.GET, '/user/<file>.png')
            ..on(HTTPMethod.GET, '/user/<file>.png/download')
            ..on(HTTPMethod.GET, '/user/<hello>.png/<user2>/hello');
        } catch (error) {
          exceptionThrown = true;
          expect(error, isA<ArgumentError>());
          error as ArgumentError;
          expect(error.message,
              contains('Route has inconsistent name in parametric definition'));
          expect(error.message, contains('<file>.png'));
          expect(error.message, contains('<hello>.png'));
        }

        expect(exceptionThrown, isTrue);
      });
    });

    test('with request.url contains dash', () {
      final config = const RadixRouterConfig(caseSensitive: false);
      final router = RadixRouter(config: config)
        ..on(HTTPMethod.GET, '/a/<param>/b');

      final result = router.lookup(HTTPMethod.GET, '/a/foo-bar/b');
      expect(result, havingParameters({'param': 'foo-bar'}));
    });

    test('with fixed suffix', () async {
      final config = const RadixRouterConfig(caseSensitive: false);
      final router = RadixRouter(config: config)
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
