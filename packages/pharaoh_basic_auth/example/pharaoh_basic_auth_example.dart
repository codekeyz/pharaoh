import 'package:pharaoh/pharaoh.dart';
import 'package:pharaoh_basic_auth/src/basic_auth.dart';

void main() async {
  final app = Pharaoh();

  app.use(basicAuth(users: {"foo": "foo-bar-pass"}));

  app.get('/', (req, res) => res.ok('Hurray 🔥'));

  await app.listen();
}
