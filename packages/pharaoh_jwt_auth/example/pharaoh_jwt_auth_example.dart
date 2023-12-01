import 'package:pharaoh/pharaoh.dart';
import 'package:pharaoh_jwt_auth/pharaoh_jwt_auth.dart';

void main() async {
  final app = Pharaoh();

  app.use(jwtAuth(secret: () => SecretKey('some-secret-key')));

  app.get('/', (req, res) => res.ok('Hello World'));

  await app.listen();
}
