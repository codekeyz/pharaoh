import 'dart:io';

import 'package:pharaoh/pharaoh.dart';
import 'package:supertest/supertest.dart';
import 'package:test/test.dart';

void main() {
  group('res.type(ContentType)', () {
    test('should set the Content-Type with type/subtype', () async {
      final app = Pharaoh().get('/', (req, res) {
        return res
            .type(ContentType.parse('application/vnd.amazon.ebook'))
            .send('var name = "tj";');
      });

      final result = await (await request<Pharaoh>(app)).get('/');
      expect(result.headers['content-type'],
          'application/vnd.amazon.ebook; charset=utf-8');
      expect(result.statusCode, 200);
      expect(result.body, 'var name = "tj";');
    });
  });
}
