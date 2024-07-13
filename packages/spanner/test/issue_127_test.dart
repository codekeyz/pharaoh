import 'package:spanner/spanner.dart';
import 'package:test/test.dart';

void main() {
  test("ALL as fallback for specific method", () {
    final router = Spanner()
      ..addRoute(HTTPMethod.GET, '/api/auth/login', 4)
      ..addRoute(HTTPMethod.ALL, '/api/auth/login', 5);

    var result = router.lookup(HTTPMethod.GET, '/api/auth/login');
    expect(result?.values, [4]);

    result = router.lookup(HTTPMethod.POST, '/api/auth/login');
    expect(result?.values, [5]);
  });
}
