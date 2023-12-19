import 'dart:convert';
import 'dart:io';

import 'package:pharaoh/pharaoh.dart';
import 'package:spookie/spookie.dart';

void main() {
  group("spookie", () {
    group('when initialized', () {
      test('should fire up the app on an ephemeral port', () async {
        final app = Pharaoh()..get('/', (req, res) => res.send('Hello World'));
        await (await (request<Pharaoh>(app))).get('/').expectStatus(200).expectBody('Hello World').test();
      });

      test('should work with an active server', () async {
        final app = Pharaoh()..post('/hello', (req, res) => res.ok('Hello World'));
        await (await (request<Pharaoh>(app))).get('/').expectStatus(404).test();
        await (await (request<Pharaoh>(app))).post('/hello', {}).expectStatus(200).test();
      });

      test('should work with remote server', () async {
        final app = Pharaoh()..put('/hello', (req, res) => res.ok('Hey Daddy Yo!'));

        await app.listen(port: 0);

        await (await (request<Pharaoh>(app))).put('/hello').expectStatus(200).expectBody('Hey Daddy Yo!').test();

        await app.shutdown();
      });
    });

    group('when expectBody', () {
      test('should work with encoded value', () async {
        final app = Pharaoh()..get('/', (req, res) => res.json({'firstname': 'Foo', 'lastname': 'Bar'}));

        await (await (request<Pharaoh>(app)))
            .get('/')
            .expectStatus(200)
            .expectBody(jsonEncode({'firstname': 'Foo', 'lastname': 'Bar'}))
            .test();
      });

      test('should work with Map value', () async {
        final app = Pharaoh()..get('/', (req, res) => res.json({'firstname': 'Foo', 'lastname': 'Bar'}));

        await (await (request<Pharaoh>(app)))
            .get('/')
            .expectStatus(200)
            .expectBody({'firstname': 'Foo', 'lastname': 'Bar'}).test();
      });
    });

    test('when expectBodyCustom', () async {
      final app = Pharaoh()..get('/', (req, res) => res.json({'name': 'Chima', 'lastname': 'Bar'}));

      await (await (request<Pharaoh>(app)))
          .get('/')
          .expectStatus(200)
          .expectBodyCustom((body) => jsonDecode(body)['name'], 'Chima')
          .test();
    });

    test('when expectJsonBody', () async {
      final app = Pharaoh()..get('/', (req, res) => res.json({'firstname': 'Foo', 'lastname': 'Bar'}));

      await (await (request<Pharaoh>(app)))
          .get('/')
          .expectStatus(200)
          .expectJsonBody({'firstname': 'Foo', 'lastname': 'Bar'}).test();
    });

    test('when expectContentType', () async {
      final app = Pharaoh()..get('/', (req, res) => res.ok('Pookie & Reyrey'));

      await (await (request<Pharaoh>(app)))
          .get('/')
          .expectStatus(200)
          .expectContentType('text/plain; charset=utf-8')
          .test();
    });

    test('when expectStatus', () async {
      final app = Pharaoh()..get('/', (req, res) => res.json('Pookie & Reyrey', statusCode: 500));

      await (await (request<Pharaoh>(app))).get('/').expectStatus(500).test();
    });

    test('when expectHeader', () async {
      final app = Pharaoh()..get('/', (req, res) => res.json('Pookie & Reyrey', statusCode: 500));

      await (await (request<Pharaoh>(app))).get('/').expectHeader(HttpHeaders.contentLengthHeader, '17').test();
    });
  });
}
