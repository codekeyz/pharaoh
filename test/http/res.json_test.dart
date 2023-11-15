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

      final result = await (await request(app)).get('/');
      expect(result.headers['content-type'],
          'application/vnd.example+json; charset=utf-8');
      expect(result.statusCode, 200);
      expect(result.body, '{"hello":"world"}');
    });

    group('when given primitives', () {
      test('should respond with json for null', () async {
        final app = Pharaoh().use((req, res, next) {
          next(res.json(null));
        });

        final result = await (await request(app)).get('/');
        expect(result.statusCode, 200);
        expect(result.body, 'null');
      });
    });
  });
}
