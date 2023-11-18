import 'dart:io';

import 'package:pharaoh/pharaoh.dart';
import 'package:supertest/supertest.dart';
import 'package:test/test.dart';

void main() {
  group('res.set(String headerKey, String headerValue)', () {
    test('should set the response header field', () async {
      final app = Pharaoh().use((req, res, next) {
        res = res.type(ContentType.parse('text/x-foo; charset=utf-8')).end();
        next(res);
      });

      final result = await (await request<Pharaoh>(app)).get('/');
      expect(result.headers['content-type'], 'text/x-foo; charset=utf-8');
      expect(result.statusCode, 200);
    });
  });
}
