import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:pharaoh/pharaoh.dart';
import 'package:supertest/supertest.dart';
import 'package:test/test.dart';

void main() {
  group('.send(String)', () {
    test('should send as html', () async {
      final app = Pharaoh();

      app.use((req, res, next) {
        next(res.send("<p>Hey</p>"));
      });

      final result = await (await request<Pharaoh>(app)).get('/');
      expect(result.headers['content-type'], 'text/html; charset=utf-8');
      expect(result.statusCode, 200);
      expect(result.body, '<p>Hey</p>');
    });

    test('should not override previous Content-Types', () async {
      final app = Pharaoh();

      app.use((req, res, next) {
        next(res.send("<p>Hey</p>"));
      });

      final result = await (await request<Pharaoh>(app)).get('/');
      expect(result.headers['content-type'], 'text/html; charset=utf-8');
      expect(result.statusCode, 200);
      expect(result.body, '<p>Hey</p>');
    });

    test('should not override previous Content-Types', () async {
      final app = Pharaoh();

      app.use((req, res, next) {
        next(res.type(ContentType.text).send("<p>Hey</p>"));
      });

      final result = await (await request<Pharaoh>(app)).get('/');
      expect(result.headers['content-type'], 'text/plain; charset=utf-8');
      expect(result.statusCode, 200);
      expect(result.body, '<p>Hey</p>');
    });

    test('should override charset in Content-Type', () async {
      final app = Pharaoh();

      app.use((req, res, next) {
        res = res
          ..updateHeaders((headers) =>
              headers['content-type'] = 'text/plain; charset=iso-8859-1');

        next(res.send('Hey'));
      });

      final result = await (await request<Pharaoh>(app)).get('/');
      expect(result.headers['content-type'], 'text/plain; charset=utf-8');
      expect(result.statusCode, 200);
      expect(result.body, 'Hey');
    });

    test('should keep charset in Content-Type for Buffers', () async {
      final app = Pharaoh();

      app.use((req, res, next) {
        res = res
          ..updateHeaders((headers) =>
              headers['content-type'] = 'text/plain; charset=iso-8859-1');
        final buffer = Uint8List.fromList(utf8.encode("Hello World"));

        next(res.send(buffer));
      });

      final result = await (await request<Pharaoh>(app)).get('/');
      expect(result.headers['content-type'], 'text/plain; charset=iso-8859-1');
      expect(result.statusCode, 200);
      expect(result.body, 'Hello World');
    });
  });

  group('.send(Buffer)', () {
    test('should send as octet-stream', () async {
      final app = Pharaoh();

      app.use((req, res, next) {
        final buffer = Uint8List.fromList(utf8.encode("Hello World"));
        next(res.send(buffer));
      });

      final result = await (await request<Pharaoh>(app)).get('/');
      expect(result.headers['content-type'], 'application/octet-stream');
      expect(result.statusCode, 200);
      expect(result.body, "Hello World");
    });
  });
}
