# spanner 🎢

Generic HTTP Router implementation, internally uses a Radix Tree (aka compact Prefix Tree), supports route params, wildcards.

```dart
    test('with fixed suffix', () async {
      final router = Spanner()
        ..addRoute(HTTPMethod.GET, '/user', null)
        ..addRoute(HTTPMethod.GET, '/user/<userId>', null)
        ..addRoute(HTTPMethod.GET, '/user/<userId>/details', null)
        ..addRoute(HTTPMethod.GET, '/user/<file>.png/download', null)
        ..addRoute(HTTPMethod.GET, '/user/<file>.png/<user2>/hello', null)
        ..addRoute(HTTPMethod.GET, '/a/<param>-static', null)
        ..addRoute(HTTPMethod.GET, '/b/<param>.static', null);

    });
```