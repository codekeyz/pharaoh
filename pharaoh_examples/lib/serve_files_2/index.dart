import 'package:pharaoh/pharaoh.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

final app = Pharaoh();

final serveStatic = createStaticHandler(
  'public/web_demo_2',
  defaultDocument: 'index.html',
);

final cors = corsHeaders();

void main() async {
  app.addRequestHook(logRequestHook);

  app.use(useShelfMiddleware(cors));

  app.use(useShelfMiddleware(serveStatic));

  await app.listen();
}
