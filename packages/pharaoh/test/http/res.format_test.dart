import 'dart:io';

import 'package:pharaoh/pharaoh.dart';
import 'package:spookie/spookie.dart';

void main() {
  group('res.format(Map<String, Function(Response)> options)', () {
    test('should respond using :accept provided', () async {
      final app = Pharaoh()
        ..get(
          '/',
          (req, res) => res.format({
            ContentType.text.toString(): (res) => res.ok('Hello World'),
            ContentType.html.toString(): (res) => res.send('<p>Hello World</p>'),
          }),
        );

      await (await request<Pharaoh>(app))
          .get(
            '/',
            headers: {HttpHeaders.acceptHeader: ContentType.text.toString()},
          )
          .expectStatus(200)
          .expectContentType('text/plain; charset=utf-8')
          .expectBody('Hello World')
          .test();

      await (await request<Pharaoh>(app))
          .get(
            '/',
            headers: {HttpHeaders.acceptHeader: ContentType.html.toString()},
          )
          .expectStatus(200)
          .expectContentType('text/html; charset=utf-8')
          .expectBody('<p>Hello World</p>')
          .test();
    });

    test('should respond using default when :accept not provided', () async {
      final app = Pharaoh()
        ..get(
          '/',
          (req, res) => res.format({
            ContentType.text.toString(): (res) => res.ok('Hello World'),
            ContentType.html.toString(): (res) => res.send('<p>Hello World</p>'),
            '_': (res) => res.json({'message': 'Hello World'})
          }),
        );

      await (await request<Pharaoh>(app))
          .get('/')
          .expectStatus(200)
          .expectContentType('application/json; charset=utf-8')
          .expectBody('{"message":"Hello World"}')
          .test();
    });

    test('should send error when :accept not supported', () async {
      final app = Pharaoh()
        ..get(
          '/',
          (req, res) => res.format({
            ContentType.text.toString(): (res) => res.ok('Hello World'),
            ContentType.html.toString(): (res) => res.send('<p>Hello World</p>'),
          }),
        );

      await (await request<Pharaoh>(app))
          .get(
            '/',
            headers: {HttpHeaders.acceptHeader: ContentType.binary.toString()},
          )
          .expectStatus(406)
          .expectContentType('application/json; charset=utf-8')
          .expectBody('{"path":"/","method":"GET","message":"Not Acceptable"}')
          .test();
    });
  });
}
