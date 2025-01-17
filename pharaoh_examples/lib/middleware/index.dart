import 'package:pharaoh/pharaoh.dart';

final app = Pharaoh();

void main() async {
  app.addRequestHook(logRequestHook);

  app.get('/', (req, res) => res.ok("Hurray 🚀"));

  await app.listen();
}
