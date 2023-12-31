import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:pharaoh/pharaoh.dart';
import 'package:spookie/spookie.dart';

void main() {
  group('.send(Object)', () {
    test('should send <String> send as html', () async {
      final app = Pharaoh();

      app.use((req, res, next) {
        next(res.send("<p>Hey</p>"));
      });

      await (await request<Pharaoh>(app))
          .get('/')
          .expectStatus(200)
          .expectBody('<p>Hey</p>')
          .expectContentType('text/html; charset=utf-8')
          .test();
    });

    test('should not override previous Content-Types', () async {
      final app = Pharaoh();

      app.use((req, res, next) {
        next(res.send("<p>Hey</p>"));
      });

      await (await request<Pharaoh>(app))
          .get('/')
          .expectContentType('text/html; charset=utf-8')
          .expectStatus(200)
          .expectBody('<p>Hey</p>')
          .test();
    });

    test('should not override previous Content-Types', () async {
      final app = Pharaoh();

      app.use((req, res, next) {
        next(res.type(ContentType.text).send("<p>Hey</p>"));
      });

      await (await request<Pharaoh>(app))
          .get('/')
          .expectContentType('text/plain; charset=utf-8')
          .expectStatus(200)
          .expectBody('<p>Hey</p>')
          .test();
    });

    test('should override charset in Content-Type', () async {
      final app = Pharaoh();

      app.use((req, res, next) {
        res = res.header('content-type', 'text/plain; charset=iso-8859-1');

        next(res.send('Hey'));
      });

      await (await request<Pharaoh>(app))
          .get('/')
          .expectStatus(200)
          .expectContentType('text/plain; charset=utf-8')
          .expectBody('Hey')
          .test();
    });

    test('should keep charset in Content-Type for <Buffers>', () async {
      final app = Pharaoh();

      app.use((req, res, next) {
        res = res.header('content-type', 'text/plain; charset=iso-8859-1');
        final buffer = Uint8List.fromList(utf8.encode("Hello World"));

        next(res.send(buffer));
      });

      await (await request<Pharaoh>(app))
          .get('/')
          .expectStatus(200)
          .expectContentType('text/plain; charset=iso-8859-1')
          .expectBody('Hello World')
          .test();
    });

    test('should send <Buffer> as octet-stream', () async {
      final app = Pharaoh();

      app.use((req, res, next) {
        final buffer = Uint8List.fromList(utf8.encode("Hello World"));
        next(res.send(buffer));
      });

      await (await request<Pharaoh>(app))
          .get('/')
          .expectStatus(200)
          .expectBody('Hello World')
          .expectContentType('application/octet-stream')
          .test();
    });
  });
}
