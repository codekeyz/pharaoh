import 'package:pharaoh/pharaoh.dart';
import 'package:supertest/supertest.dart';
import 'package:test/test.dart';

void main() {
  group("supertest", () {
    test('should fire up the app on an ephemeral port', () async {
      final app = Pharaoh().get('/', (req, res) => res.send('Hello World'));
      final result = await (await (request<Pharaoh>(app))).get('/');
      expect(result.statusCode, 200);
      expect(result.body, 'Hello World');
    });

    test('should work with an active server', () async {
      final app = Pharaoh().post('/hello', (req, res) => res.ok('Hello World'));
      var result = await (await (request<Pharaoh>(app))).get('/');
      expect(result.statusCode, 404);

      result = await (await (request<Pharaoh>(app))).post('/hello');
      expect(result.statusCode, 200);
    });

    test('should work with remote server', () async {
      final app =
          Pharaoh().put('/hello', (req, res) => res.ok('Hey Daddy Yo!'));

      await app.listen();

      var result = await (await (request<Pharaoh>(app))).put('/hello');
      expect(result.statusCode, 200);
      expect(result.body, 'Hey Daddy Yo!');
    });
  });
}
