# spanner 🎢

Generic HTTP Router implementation, internally uses a Radix Tree (aka compact Prefix Tree), supports route params, wildcards.

```dart
import 'package:spanner/spanner.dart';
import 'package:test/test.dart';

void main() {
   test('spanner sample test', () {
    routeHandler() async {}

    final router = Spanner()
      ..addMiddleware('/user', #userMiddleware)
      ..addRoute(HTTPMethod.GET, '/user', #currentUser)
      ..addRoute(HTTPMethod.GET, '/user/<userId>', 123)
      ..addRoute(HTTPMethod.GET, '/user/<file>.png/download', null)
      ..addRoute(HTTPMethod.GET, '/user/<file>.png/<user2>/hello', null)
      ..addRoute(HTTPMethod.GET, '/a/<userId>-static', routeHandler);

    var result = router.lookup(HTTPMethod.GET, '/user');
    expect(result!.values, [#userMiddleware, #currentUser]);

    result = router.lookup(HTTPMethod.GET, '/user/24');
    expect(result?.params, {'userId': '24'});
    expect(result?.values, [#userMiddleware, 123]);

    result = router.lookup(HTTPMethod.GET, '/user/aws-image.png/download');
    expect(result?.params, {'file': 'aws-image'});

    result = router.lookup(HTTPMethod.GET, '/user/aws-image.png/A29384/hello');
    expect(result?.params, {'file': 'aws-image', 'user2': 'A29384'});

    result = router.lookup(HTTPMethod.GET, '/a/chima-static');
    expect(result?.values, [routeHandler]);
    expect(result?.params, {'userId': 'chima'});
  });
}

```
