import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:pharaoh/pharaoh.dart';
import 'package:pharaoh_jwt_auth/pharaoh_jwt_auth.dart';

void main() async {
  final app = Pharaoh();
  final jwtConfig = PharaohJwtConfig(
    algorithms: [JWTAlgorithm.HS256],
    secret: SecretKey('some-secret-key'),
    authRequired: true,
  );

  app.use(jwtAuth(jwtConfig));

  app.get('/', (req, res) => res.ok('Hello World'));

  await app.listen();
}
