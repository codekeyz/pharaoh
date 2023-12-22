import 'package:spanner/spanner.dart';
import 'package:test/test.dart';

void main() {
  group('wildcard_test', () {
    test('when wildcard with HTTPMethod.ALL', () {
      final router = Spanner()..addRoute(HTTPMethod.ALL, '/*', 'mee-moo');

      var result = router.lookup(HTTPMethod.GET, '/hello-world');
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
      expect(result?.values, null);
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

    test('static route and wildcard on same method with additional HTTPMETHOD.ALL', () {
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

    test('contain param and wildcard together', () {
      final router = Spanner()
        ..addRoute(HTTPMethod.GET, '/<lang>/item/<id>', 'id-man')
        ..addRoute(HTTPMethod.GET, '/<lang>/*', 'wee-wee');

      var result = router.lookup(HTTPMethod.GET, '/fr/item/12345');
      expect(result?.values, ['id-man']);

      result = router.lookup(HTTPMethod.GET, '/fr/ajsdkflajsdfj');
      expect(result?.values, ['wee-wee']);
    });
  });
}
