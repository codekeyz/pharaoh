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
          .status(200)
          .body('<p>Hey</p>')
          .contentType('text/html; charset=utf-8')
          .test();
    });

    test('should not override previous Content-Types', () async {
      final app = Pharaoh();

      app.use((req, res, next) {
        next(res.send("<p>Hey</p>"));
      });

      await (await request<Pharaoh>(app))
          .get('/')
          .contentType('text/html; charset=utf-8')
          .status(200)
          .body('<p>Hey</p>')
          .test();
    });

    test('should not override previous Content-Types', () async {
      final app = Pharaoh();

      app.use((req, res, next) {
        next(res.type(ContentType.text).send("<p>Hey</p>"));
      });

      await (await request<Pharaoh>(app))
          .get('/')
          .contentType('text/plain; charset=utf-8')
          .status(200)
          .body('<p>Hey</p>')
          .test();
    });

    test('should override charset in Content-Type', () async {
      final app = Pharaoh();

      app.use((req, res, next) {
        res = res.set('content-type', 'text/plain; charset=iso-8859-1');

        next(res.send('Hey'));
      });

      await (await request<Pharaoh>(app))
          .get('/')
          .status(200)
          .contentType('text/plain; charset=utf-8')
          .body('Hey')
          .test();
    });

    test('should keep charset in Content-Type for <Buffers>', () async {
      final app = Pharaoh();

      app.use((req, res, next) {
        res = res.set('content-type', 'text/plain; charset=iso-8859-1');
        final buffer = Uint8List.fromList(utf8.encode("Hello World"));

        next(res.send(buffer));
      });

      await (await request<Pharaoh>(app))
          .get('/')
          .status(200)
          .contentType('text/plain; charset=iso-8859-1')
          .body('Hello World')
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
          .status(200)
          .body('Hello World')
          .contentType('application/octet-stream')
          .test();
    });
  });
}
