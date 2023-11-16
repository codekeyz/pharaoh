import 'dart:io';

import 'package:pharaoh/pharaoh.dart';
import 'package:supertest/supertest.dart';
import 'package:test/test.dart';

void main() {
  group('.json(Object)', () {
    test('should not override previous Content-Types', () async {
      final app = Pharaoh().get('/', (req, res) {
        return res
            .type(ContentType.parse('application/vnd.example+json'))
            .json({"hello": "world"});
      });

      final result = await (await request<Pharaoh>(app)).get('/');
      expect(result.headers['content-type'], 'application/vnd.example+json');
      expect(result.statusCode, 200);
      expect(result.body, '{"hello":"world"}');
    });

    group('when given primitives', () {
      test('should respond with json for <null>', () async {
        final app = Pharaoh().use((req, res, next) {
          next(res.json(null));
        });

        final result = await (await request<Pharaoh>(app)).get('/');
        expect(result.statusCode, 200);
        expect(result.body, 'null');
        expect(
            result.headers['content-type'], 'application/json; charset=utf-8');
      });

      test('should respond with json for <int>', () async {
        final app = Pharaoh().use((req, res, next) {
          next(res.json(300));
        });

        final result = await (await request(app)).get('/');
        expect(result.statusCode, 200);
        expect(result.body, '300');
        expect(
            result.headers['content-type'], 'application/json; charset=utf-8');
      });

      test('should respond with json for <double>', () async {
        final app = Pharaoh().use((req, res, next) {
          next(res.json(300.34));
        });

        final result = await (await request(app)).get('/');
        expect(result.statusCode, 200);
        expect(result.body, '300.34');
        expect(
            result.headers['content-type'], 'application/json; charset=utf-8');
      });

      test('should respond with json for <String>', () async {
        final app = Pharaoh().use((req, res, next) {
          next(res.json("str"));
        });

        final result = await (await request(app)).get('/');
        expect(result.statusCode, 200);
        expect(result.body, '"str"');
        expect(
            result.headers['content-type'], 'application/json; charset=utf-8');
      });

      test('should respond with json for <bool>', () async {
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

    group('when given a collection type', () {
      test('<List> should respond with json', () async {
        final app = Pharaoh().use((req, res, next) {
          next(res.json(["foo", "bar", "baz"]));
        });

        final result = await (await request(app)).get('/');
        expect(result.statusCode, 200);
        expect(result.body, '["foo","bar","baz"]');
        expect(
            result.headers['content-type'], 'application/json; charset=utf-8');
      });

      test('<Map> should respond with json', () async {
        final app = Pharaoh().use((req, res, next) {
          next(res.json({"name": "Foo bar", "age": 23.45}));
        });

        final result = await (await request(app)).get('/');
        expect(result.statusCode, 200);
        expect(result.body, '{"name":"Foo bar","age":23.45}');
        expect(
            result.headers['content-type'], 'application/json; charset=utf-8');
      });

      test('<Set> should respond with json', () async {
        final app = Pharaoh().use((req, res, next) {
          next(res.json({"Chima", "Foo", "Bar"}));
        });

        final result = await (await request(app)).get('/');
        expect(result.statusCode, 200);
        expect(result.body, '["Chima","Foo","Bar"]');
        expect(
            result.headers['content-type'], 'application/json; charset=utf-8');
      });
    });
  });
}
