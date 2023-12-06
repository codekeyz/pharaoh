# pharaoh_static 🗃

Pharaoh Middleware that serves static files such as images, CSS files, and JavaScript files. It takes a root directory as an argument, which is the directory from which to serve static files.

## Installing:

In your pubspec.yaml

```yaml
dependencies:
  pharaoh: ^0.0.5
  pharaoh_static:
```

## Basic Usage:

```dart
import 'package:pharaoh/pharaoh.dart';
import 'package:pharaoh_static/pharaoh_static.dart';

final app = Pharaoh();

final serveStatic = createStaticHandler(
  'public',
  defaultDocument: 'index.html',
);

void main() async {

  app.use(serveStatic);

  await app.listen();

}
```

## Tests

The cases in the `pharaoh_static_test.dart` are also used for automated testing. So if you want  
to contribute or just make sure that the package still works, simply run:

```shell
dart test
```
