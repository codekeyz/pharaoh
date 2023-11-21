import 'package:pharaoh/pharaoh.dart';
import 'package:supertest/supertest.dart';

void main() {
  group("supertest", () {
    test('should fire up the app on an ephemeral port', () async {
      final app = Pharaoh().get('/', (req, res) => res.send('Hello World'));
      await (await (request<Pharaoh>(app)))
          .get('/')
          .status(200)
          .body('Hello World')
          .test();
    });

    test('should work with an active server', () async {
      final app = Pharaoh().post('/hello', (req, res) => res.ok('Hello World'));
      await (await (request<Pharaoh>(app))).get('/').status(404).test();
      await (await (request<Pharaoh>(app))).post('/hello').status(200).test();
    });

    test('should work with remote server', () async {
      final app =
          Pharaoh().put('/hello', (req, res) => res.ok('Hey Daddy Yo!'));

      await app.listen();

      await (await (request<Pharaoh>(app)))
          .put('/hello')
          .status(200)
          .body('Hey Daddy Yo!')
          .test();

      await app.shutdown();
    });
  });
}
