import 'dart:io';

import 'package:pharaoh/pharaoh.dart';
import 'package:spookie/spookie.dart';

void main() {
  group('.json(Object)', () {
    test('should not override previous Content-Types', () async {
      final app = Pharaoh()
        ..get('/', (req, res) {
          return res
              .type(ContentType.parse('application/vnd.example+json'))
              .json({"hello": "world"});
        });

      await (await request<Pharaoh>(app))
          .get('/')
          .expectStatus(200)
          .expectContentType('application/vnd.example+json')
          .expectBody('{"hello":"world"}')
          .test();
    });

    test('should catch object serialization errors', () async {
      final app = Pharaoh()..get('/', (req, res) => res.json(Never));

      await (await request<Pharaoh>(app))
          .get('/')
          .expectStatus(500)
          .expectBody({
            'path': '/',
            'method': 'GET',
            'message': "Converting object to an encodable object failed: Never"
          })
          .expectContentType('application/json; charset=utf-8')
          .test();
    });

    group('when given primitives', () {
      test('should respond with json for <null>', () async {
        final app = Pharaoh()..use((req, res, next) => next(res.json(null)));

        await (await request<Pharaoh>(app))
            .get('/')
            .expectStatus(200)
            .expectBody('null')
            .expectContentType('application/json; charset=utf-8')
            .test();
      });

      test('should respond with json for <int>', () async {
        final app = Pharaoh()..use((req, res, next) => next(res.json(300)));

        await (await request<Pharaoh>(app))
            .get('/')
            .expectStatus(200)
            .expectBody('300')
            .expectContentType('application/json; charset=utf-8')
            .test();
      });

      test('should respond with json for <double>', () async {
        final app = Pharaoh()..use((req, res, next) => next(res.json(300.34)));

        await (await request<Pharaoh>(app))
            .get('/')
            .expectStatus(200)
            .expectBody('300.34')
            .expectContentType('application/json; charset=utf-8')
            .test();
      });

      test('should respond with json for <String>', () async {
        final app = Pharaoh()..use((req, res, next) => next(res.json("str")));

        await (await request<Pharaoh>(app))
            .get('/')
            .expectStatus(200)
            .expectBody('"str"')
            .expectContentType('application/json; charset=utf-8')
            .test();
      });

      test('should respond with json for <bool>', () async {
        final app = Pharaoh()..use((req, res, next) => next(res.json(true)));

        await (await request<Pharaoh>(app))
            .get('/')
            .expectStatus(200)
            .expectBody('true')
            .expectContentType('application/json; charset=utf-8')
            .test();
      });
    });

    group('when given a collection type', () {
      test('<List> should respond with json', () async {
        final app = Pharaoh()
          ..use((req, res, next) => next(res.json(["foo", "bar", "baz"])));

        await (await request<Pharaoh>(app))
            .get('/')
            .expectStatus(200)
            .expectBody('["foo","bar","baz"]')
            .expectContentType('application/json; charset=utf-8')
            .test();
      });

      test('<Map> should respond with json', () async {
        final app = Pharaoh()
          ..use((req, res, next) => next(res.json({"name": "Foo bar", "age": 23.45})));

        await (await request<Pharaoh>(app))
            .get('/')
            .expectStatus(200)
            .expectBody('{"name":"Foo bar","age":23.45}')
            .expectContentType('application/json; charset=utf-8')
            .test();
      });

      test('<Set> should respond with json', () async {
        final app = Pharaoh()
          ..use((req, res, next) => next(res.json({"Chima", "Foo", "Bar"})));

        await (await request<Pharaoh>(app))
            .get('/')
            .expectStatus(200)
            .expectBody('["Chima","Foo","Bar"]')
            .expectContentType('application/json; charset=utf-8')
            .test();
      });
    });
  });
}
