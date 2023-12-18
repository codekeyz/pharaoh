# pharaoh_basic_auth 🏴

Simple plug & play HTTP basic auth middleware for Pharaoh.

## Installing:

In your pubspec.yaml

```yaml
dependencies:
  pharaoh: ^0.0.5+6
  pharaoh_basic_auth:
```

## Basic Usage:

```dart
import 'package:pharaoh/pharaoh.dart';
import 'package:pharaoh_basic_auth/src/basic_auth.dart';

void main() async {
  final app = Pharaoh();

  app.use(basicAuth(users: {"admin": "supersecret"}));
}
```

The middleware will now check incoming requests to match the credentials
`admin:supersecret`.

The middleware will check incoming requests for a basic auth (`Authorization`)
header, parse it and check if the credentials are legit. If there are any
credentials, the `auth` property on the `request` will contain the `user` and `password` properties.

**If a request is found to not be authorized**, it will respond with HTTP 401
and a configurable body (default `Unauthorized`).

### Static Users

If you simply want to check basic auth against one or multiple static credentials,
you can pass those credentials in the `users` option:

```dart
 app.use(basicAuth(
    users: {
      "admin": "supersecret",
      "adam": "password1234",
      "eve": "asdfghjkl",
    },
));
```

The middleware will check incoming requests to have a basic auth header matching
one of the three passed credentials.

### Custom authorization

Alternatively, you can pass your own `authorizer` function, to check the credentials
however you want. It will be called with a username and password and is expected to
return `true` or `false` to indicate that the credentials were approved or not.

When using your own `authorizer`, make sure **not to use standard string comparison (`==`)**
when comparing user input with secret credentials, as that would make you vulnerable against
[timing attacks](https://en.wikipedia.org/wiki/Timing_attack). Use the provided `safeCompare`
function instead - always provide the user input as its first argument.

```dart
bool myAuthorizer(username, password) =>
              safeCompare(username, 'customuser') &&
              safeCompare(password, 'custompassword');

app.use(basicAuth(authorizer: myAuthorizer ));
```

This will authorize all requests with the credentials `customuser:custompassword`.
In an actual application you would likely look up some data instead ;-) You can do whatever you
want in custom authorizers, just return `true` or `false` in the end and stay aware of timing
attacks.

## Tests

The cases in the `basic_auth_test.dart` are also used for automated testing. So if you want  
to contribute or just make sure that the package still works, simply run:

```shell
dart test
```
