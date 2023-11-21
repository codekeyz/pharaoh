import 'dart:io';

import 'package:pharaoh/pharaoh.dart';
import 'package:spookie/spookie.dart';

void main() {
  group('.json(Object)', () {
    test('should not override previous Content-Types', () async {
      final app = Pharaoh().get('/', (req, res) {
        return res
            .type(ContentType.parse('application/vnd.example+json'))
            .json({"hello": "world"});
      });

      await (await request<Pharaoh>(app))
          .get('/')
          .status(200)
          .contentType('application/vnd.example+json')
          .body('{"hello":"world"}')
          .test();
    });

    group('when given primitives', () {
      test('should respond with json for <null>', () async {
        final app = Pharaoh().use((req, res, next) {
          next(res.json(null));
        });

        await (await request<Pharaoh>(app))
            .get('/')
            .status(200)
            .body('null')
            .contentType('application/json; charset=utf-8')
            .test();
      });

      test('should respond with json for <int>', () async {
        final app = Pharaoh().use((req, res, next) {
          next(res.json(300));
        });

        await (await request(app))
            .get('/')
            .status(200)
            .body('300')
            .contentType('application/json; charset=utf-8')
            .test();
      });

      test('should respond with json for <double>', () async {
        final app = Pharaoh().use((req, res, next) {
          next(res.json(300.34));
        });

        await (await request(app))
            .get('/')
            .status(200)
            .body('300.34')
            .contentType('application/json; charset=utf-8')
            .test();
      });

      test('should respond with json for <String>', () async {
        final app = Pharaoh().use((req, res, next) {
          next(res.json("str"));
        });

        await (await request(app))
            .get('/')
            .status(200)
            .body('"str"')
            .contentType('application/json; charset=utf-8')
            .test();
      });

      test('should respond with json for <bool>', () async {
        final app = Pharaoh().use((req, res, next) {
          next(res.json(true));
        });

        await (await request(app))
            .get('/')
            .status(200)
            .body('true')
            .contentType('application/json; charset=utf-8')
            .test();
      });
    });

    group('when given a collection type', () {
      test('<List> should respond with json', () async {
        final app = Pharaoh().use((req, res, next) {
          next(res.json(["foo", "bar", "baz"]));
        });

        await (await request(app))
            .get('/')
            .status(200)
            .body('["foo","bar","baz"]')
            .contentType('application/json; charset=utf-8')
            .test();
      });

      test('<Map> should respond with json', () async {
        final app = Pharaoh().use((req, res, next) {
          next(res.json({"name": "Foo bar", "age": 23.45}));
        });

        await (await request(app))
            .get('/')
            .status(200)
            .body('{"name":"Foo bar","age":23.45}')
            .contentType('application/json; charset=utf-8')
            .test();
      });

      test('<Set> should respond with json', () async {
        final app = Pharaoh().use((req, res, next) {
          next(res.json({"Chima", "Foo", "Bar"}));
        });

        await (await request(app))
            .get('/')
            .status(200)
            .body('["Chima","Foo","Bar"]')
            .contentType('application/json; charset=utf-8')
            .test();
      });
    });
  });
}
