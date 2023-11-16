import 'package:pharaoh/pharaoh.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

final app = Pharaoh();

void main() async {
  /// Using shelf_cors_header with Pharaoh
  app.use(useShelfMiddleware(corsHeaders()));

  app.get('/foo', (req, res) => res.json(req.headers));

  await app.listen();
}
