import 'dart:io';

import 'package:pharaoh/pharaoh.dart';
import 'package:spookie/spookie.dart';

void main() {
  group('res.redirect', () {
    test('should redirect to paths on the api', () async {
      final app = Pharaoh()
        ..get('/bar', (_, res) => res.ok('Finally here!'))
        ..get('/foo', (_, res) => res.redirect('/bar', 301));

      await (await request<Pharaoh>(app))
          .get('/foo')
          .expectStatus(HttpStatus.ok)
          .expectBody("Finally here!")
          .test();
    });

    test('should redirect to remote paths', () async {
      final app = Pharaoh()
        ..get('/foo', (_, res) => res.redirect('https://example.com', 301));

      await (await request<Pharaoh>(app))
          .get('/foo')
          .expectStatus(HttpStatus.ok)
          .expectBody(contains('Example Domain'))
          .test();
    });
  });
}
