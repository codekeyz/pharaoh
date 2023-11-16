import 'dart:io';

import 'package:pharaoh/pharaoh.dart';
import 'package:supertest/supertest.dart';
import 'package:test/test.dart';

void main() {
  group('.json(Object)', () {
    test('should not override previous Content-Types', () async {
      final app = Pharaoh().get('/', (req, res) {
        return res.type(ContentType.parse('application/vnd.example+json')).json({"hello": "world"});
      });

      final result = await (await request<Pharaoh>(app)).get('/');
      expect(result.headers['content-type'], 'application/vnd.example+json; charset=utf-8');
      expect(result.statusCode, 200);
      expect(result.body, '{"hello":"world"}');
    });

    group('when given primitives', () {
      test('should respond with json for null', () async {
        final app = Pharaoh().use((req, res, next) {
          next(res.json(null));
        });

        final result = await (await request<Pharaoh>(app)).get('/');
        expect(result.statusCode, 200);
        expect(result.body, 'null');
        expect(
            result.headers['content-type'], 'application/json; charset=utf-8');
      });

      test('should respond with json for Integer', () async {
        final app = Pharaoh().use((req, res, next) {
          next(res.json(300));
        });

        final result = await (await request(app)).get('/');
        expect(result.statusCode, 200);
        expect(result.body, '300');
        expect(
            result.headers['content-type'], 'application/json; charset=utf-8');
      });

      test('should respond with json for Double', () async {
        final app = Pharaoh().use((req, res, next) {
          next(res.json(300.34));
        });

        final result = await (await request(app)).get('/');
        expect(result.statusCode, 200);
        expect(result.body, '300.34');
        expect(
            result.headers['content-type'], 'application/json; charset=utf-8');
      });

      test('should respond with json for String', () async {
        final app = Pharaoh().use((req, res, next) {
          next(res.json("str"));
        });

        final result = await (await request(app)).get('/');
        expect(result.statusCode, 200);
        expect(result.body, '"str"');
        expect(
            result.headers['content-type'], 'application/json; charset=utf-8');
      });

      test('should respond with json for Boolean', () async {
        final app = Pharaoh().use((req, res, next) {
          next(res.json(true));
        });

        final result = await (await request(app)).get('/');
        expect(result.statusCode, 200);
        expect(result.body, 'true');
        expect(
            result.headers['content-type'], 'application/json; charset=utf-8');
      });
    });

    group('when given an array', () {
      test('should respond with json', () async {
        final app = Pharaoh().use((req, res, next) {
          next(res.json(["foo", "bar", "baz"]));
        });

        final result = await (await request(app)).get('/');
        expect(result.statusCode, 200);
        expect(result.body, '["foo","bar","baz"]');
        expect(
            result.headers['content-type'], 'application/json; charset=utf-8');
      });
    });
  });
}
