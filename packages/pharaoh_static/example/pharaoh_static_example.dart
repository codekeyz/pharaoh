import 'package:pharaoh/pharaoh.dart';
import 'package:pharaoh_static/src/static_handler.dart';

final serveStatic = createStaticHandler(
  'public',
  defaultDocument: 'index.html',
);

void main() async {
  final app = Pharaoh();

  app.use(serveStatic);

  app.get('/', (req, res) => res.ok('Hurray 🔥'));

  await app.listen();
}
