import 'dart:convert';

import 'package:pharaoh/pharaoh.dart';
import 'package:supertest/supertest.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {});

  group('.json(Object)', () {
    test('should not support jsonp callbacks', () async {
      final app = Pharaoh()
          .get('/repos', (req, res) => res.json("Hello World"))
          .post('/create', (req, res) => res.json([1, 2, 3, 4]));

      var result = await (await request(app)).get('/repos');
      expect(result.statusCode, 200);
      expect(result.body, jsonEncode("Hello World"));

      result = await (await request(app)).post('/create');
      expect(result.statusCode, 200);
      expect(result.body, jsonEncode([1, 2, 3, 4]));
      expect(result.headers['x-powered-by'], 'Pharoah');
      expect(result.headers['content-length'], '9');
      expect(result.headers['content-type'], 'application/json');
    });
  });
}
