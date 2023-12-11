# pharaoh_jwt_auth 🪭

This module provides Pharaoh middleware for validating JWTs (JSON Web Tokens) through the [dart_jsonwebtoken](https://pub.dev/packages/dart_jsonwebtoken)
package.

The decoded JWT payload is available on the request object via `req.auth`.

## Installing:

In your pubspec.yaml

```yaml
dependencies:
  pharaoh: ^0.0.5
  pharaoh_jwt_auth: ^1.0.0
```

## Basic Usage:

```dart
import 'package:pharaoh/pharaoh.dart';
import 'package:pharaoh_jwt_auth/pharaoh_jwt_auth.dart';

void main() async {
  final app = Pharaoh();

  app.use(jwtAuth(secret: () => SecretKey('some-secret-key')));

  app.get('/', (req, res) => res.ok('Hello World'));

  await app.listen();
}
```

The package also exports the [dart_jsonwebtoken](https://pub.dev/packages/dart_jsonwebtoken) package for your usage outside of this library.

## Tests

The cases in the `pharaoh_jwt_auth_test.dart` are also used for automated testing. So if you want  
to contribute or just make sure that the package still works, simply run:

```shell
dart test
```
