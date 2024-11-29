import 'package:pharaoh/pharaoh.dart';
import 'package:spookie/spookie.dart';

void main() {
  test('should error on route not found', () async {
    final app = Pharaoh()..get('/', (req, res) => res.ok('Hello'));

    final tester = await request(app);

    await tester.get('/').expectStatus(200).expectBody('Hello').test();

    await tester
        .get('/come')
        .expectStatus(404)
        .expectJsonBody({"error": "Route not found: /come"}).test();
  });
}
