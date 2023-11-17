# pharaoh-static

Porting `shelf_static` from the Dart `shelf` package to `Pharaoh`

### Example

```dart
import 'package:pharaoh/pharaoh.dart';
import 'package:pharaoh_static/pharaoh_static.dart';

final app = Pharaoh();

final serveStatic = createStaticHandler(
  'public/web_demo_2',
  defaultDocument: 'index.html',
);

void main() async {
  app.use(logRequests);

  app.use(serveStatic);

  await app.listen();
}
```
