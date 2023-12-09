import 'package:pharaoh/pharaoh.dart';
import 'package:spookie/spookie.dart';

void main() {
  group('body_parser', () {
    group('should parse request body ', () {
      test('when content-type not specified', () async {
        final app = Pharaoh()..post('/', (req, res) => res.json(req.body));

        await (await request<Pharaoh>(app))
            .post('/', {'name': 'Chima', 'age': '24'})
            .expectStatus(200)
            .expectBody({'name': 'Chima', 'age': '24'})
            .test();
      });

      test('when content-type is `application/json`', () async {
        final app = Pharaoh()..post('/', (req, res) => res.json(req.body));

        await (await request<Pharaoh>(app))
            .post('/', '{"name":"Chima","age":24}',
                headers: {'Content-Type': 'application/json'})
            .expectStatus(200)
            .expectBody({'name': 'Chima', 'age': 24})
            .test();
      });

      test('when content-type is `application/x-www-form-urlencoded`', () async {
        final app = Pharaoh()..post('/', (req, res) => res.json(req.body));

        await (await request<Pharaoh>(app))
            .post('/', 'name%3DChima%26age%3D24',
                headers: {'Content-Type': 'application/x-www-form-urlencoded'})
            .expectStatus(200)
            .expectBody({'name': 'Chima', 'age': '24'})
            .test();
      });
    });

    group('should not parse request body', () {
      test('when request body is null', () async {
        final app = Pharaoh()..post('/', (req, res) => res.json(req.body));

        await (await request<Pharaoh>(app))
            .post('/', null)
            .expectStatus(200)
            .expectBody('null')
            .test();
      });

      test('when request body is empty', () async {
        final app = Pharaoh()..post('/', (req, res) => res.json(req.body));

        await (await request<Pharaoh>(app))
            .post('/', '')
            .expectStatus(200)
            .expectBody('null')
            .test();
      });
    });
  });
}
