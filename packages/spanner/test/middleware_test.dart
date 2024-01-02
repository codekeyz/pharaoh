import 'package:spanner/spanner.dart';
import 'package:test/test.dart';

void main() {
  group('addMiddleware', () {
    test('should return middlewares', () {
      router() => Spanner()
        ..addMiddleware('/', 24)
        ..addRoute(HTTPMethod.GET, '/user', 44);

      final result = router().lookup(HTTPMethod.GET, '/user');
      expect(result?.values, [24, 44]);
    });

    test('should return Wildcard', () {
      router() => Spanner()
        ..addMiddleware('/', 24)
        ..addRoute(HTTPMethod.GET, '/user', 44)
        ..addRoute(HTTPMethod.ALL, '/*', 100);

      final result = router().lookup(HTTPMethod.GET, '/some-unknown-route');
      expect(result?.values, [24, 100]);
    });
  });
}
