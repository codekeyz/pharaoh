import 'package:pharaoh/pharaoh.dart';
import 'package:spookie/spookie.dart';

void main() {
  group("spookie", () {
    test('should fire up the app on an ephemeral port', () async {
      final app = Pharaoh()..get('/', (req, res) => res.send('Hello World'));
      await (await (request<Pharaoh>(app)))
          .get('/')
          .expectStatus(200)
          .expectBody('Hello World')
          .test();
    });

    test('should work with an active server', () async {
      final app = Pharaoh()..post('/hello', (req, res) => res.ok('Hello World'));
      await (await (request<Pharaoh>(app))).get('/').expectStatus(404).test();
      await (await (request<Pharaoh>(app))).post('/hello', {}).expectStatus(200).test();
    });

    test('should work with remote server', () async {
      final app = Pharaoh()..put('/hello', (req, res) => res.ok('Hey Daddy Yo!'));

      await app.listen(port: 0);

      await (await (request<Pharaoh>(app)))
          .put('/hello')
          .expectStatus(200)
          .expectBody('Hey Daddy Yo!')
          .test();

      await app.shutdown();
    });
  });
}
