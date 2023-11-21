import 'package:pharaoh/pharaoh.dart';
import 'package:shelf_helmet/shelf_helmet.dart';

final app = Pharaoh();

void main() async {
  /// Using shelf_helmet with Pharaoh
  app.use(useShelfMiddleware(helmet()));

  app.get('/', (req, res) => res.json(req.headers));

  await app.listen();
}
