import 'package:spanner/spanner.dart';
import 'package:test/test.dart';

void main() {
  group('wildcard_test', () {
    test('*', () {
      final router = Spanner()
        ..addMiddleware('/api', 3)
        ..addRoute(HTTPMethod.GET, '/api/auth/login', 4)
        ..addRoute(HTTPMethod.GET, '/api/users/<userId>', 5)
        ..addRoute(HTTPMethod.ALL, '/*', 'mee-moo');

      expect(
        router.lookup(HTTPMethod.GET, '/api/users/hello')?.values,
        [3, 5],
      );

      var result = router.lookup(HTTPMethod.GET, '/api');
      expect(result?.values, [3]);

      result = router.lookup(HTTPMethod.GET, '/api/users');
      expect(result?.values, [3]);

      result = router.lookup(HTTPMethod.GET, '/api/users/chima/details/home');
      expect(result?.values, [3, 'mee-moo']);
    });

    test('when wildcard with HTTPMethod.ALL', () {
      final router = Spanner()..addRoute(HTTPMethod.ALL, '/*', 'mee-moo');

      var result = router.lookup(HTTPMethod.GET, '/hello/boy');
      expect(result!.values, ['mee-moo']);

      result = router.lookup(HTTPMethod.DELETE, '/hello');
      expect(result?.values, ['mee-moo']);

      result = router.lookup(HTTPMethod.POST, '/hello');
      expect(result?.values, ['mee-moo']);
    });

    test('when wildcard with specific HTTPMethod', () {
      final router = Spanner()..addRoute(HTTPMethod.GET, '/*', 'mee-moo');

      var result = router.lookup(HTTPMethod.GET, '/hello-world');
      expect(result!.values, ['mee-moo']);

      result = router.lookup(HTTPMethod.POST, '/hello');
      expect(result?.values, const []);
    });

    test('static route and wildcard on same method', () {
      final router = Spanner()
        ..addRoute(HTTPMethod.GET, '/hello-world', 'foo-bar')
        ..addRoute(HTTPMethod.GET, '/*', 'mee-moo');

      var result = router.lookup(HTTPMethod.GET, '/hello-world');
      expect(result!.values, ['foo-bar']);

      result = router.lookup(HTTPMethod.GET, '/hello');
      expect(result?.values, ['mee-moo']);
    });

    test(
        'static route and wildcard on same method with additional HTTPMETHOD.ALL',
        () {
      final router = Spanner()
        ..addRoute(HTTPMethod.GET, '/hello-world', 'foo-bar')
        ..addRoute(HTTPMethod.GET, '/*', 'mee-moo')
        ..addRoute(HTTPMethod.ALL, '/*', 'ange-lina');

      var result = router.lookup(HTTPMethod.GET, '/hello-world');
      expect(result!.values, ['foo-bar']);

      result = router.lookup(HTTPMethod.GET, '/hello');
      expect(result?.values, ['mee-moo']);

      result = router.lookup(HTTPMethod.POST, '/hello');
      expect(result?.values, ['ange-lina']);
    });

    test('issue', () {
      final router = Spanner()
        ..addRoute(HTTPMethod.GET, '/hello/chima', 'haah')
        ..addRoute(HTTPMethod.GET, '/hello/*', 'bar')
        ..addRoute(HTTPMethod.GET, '/<userId>/hello', 'var')
        ..addRoute(HTTPMethod.GET, '/*', 'mee');

      var result = router.lookup(HTTPMethod.GET, '/hello/chima');
      expect(result?.values, ['haah']);

      result = router.lookup(HTTPMethod.GET, '/hello/come');
      expect(result?.values, ['bar']);

      result = router.lookup(HTTPMethod.GET, '/holycrap');
      expect(result?.values, ['mee']);

      result = router.lookup(HTTPMethod.GET, '/holycrap/hello');
      expect(result?.values, ['var']);

      result = router.lookup(HTTPMethod.GET, '/holycrap/hello/goat');
      expect(result?.values, ['mee']);
    });

    test('contain param and wildcard together', () {
      final router = Spanner()
        ..addRoute(HTTPMethod.GET, '/<lang>/item/<id>', 'id-man')
        ..addRoute(HTTPMethod.GET, '/*', 'wildcard');

      var result = router.lookup(HTTPMethod.GET, '/fr/item/12345');
      expect(result?.values, ['id-man']);

      result = router.lookup(HTTPMethod.GET, '/fr/item/ajsdkflajsdfj/how');
      expect(result?.values, ['wildcard']);
    });
  });
}
