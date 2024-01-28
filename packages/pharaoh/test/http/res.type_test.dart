import 'dart:io';

import 'package:pharaoh/pharaoh.dart';
import 'package:spookie/spookie.dart';

void main() {
  group('res.type(ContentType)', () {
    test('should set the Content-Type with type/subtype', () async {
      final app = Pharaoh()
        ..get('/', (req, res) {
          final cType =
              ContentType('application', 'vnd.amazon.ebook', charset: 'utf-8');

          return res.type(cType).send('var name = "tj";');
        });

      await (await request<Pharaoh>(app))
          .get('/')
          .expectStatus(200)
          .expectBody('var name = "tj";')
          .expectContentType('application/vnd.amazon.ebook; charset=utf-8')
          .test();
    });
  });
}
