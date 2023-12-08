import 'package:pharaoh/pharaoh.dart';
import 'package:spookie/spookie.dart';

void main() {
  group('req.query && req.params', () {
    test('should pass a query', () async {
      final app = Pharaoh()..get('/', (req, res) => res.json(req.query));

      await (await request<Pharaoh>(app))
          .get('/?value1=1&value2=2')
          .expectStatus(200)
          .expectBody({"value1": "1", "value2": "2"}).test();
    });
  });

  test('should pass a param', () async {
    final app = Pharaoh()..get('/<username>', (req, res) => res.json(req.params));

    await (await request<Pharaoh>(app))
        .get('/heyOnuoha')
        .expectStatus(200)
        .expectBody({"username": "heyOnuoha"}).test();
  });
}
