import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:pharaoh/pharaoh.dart';
import 'package:spookie/spookie.dart';

void main() {
  group('.send(Object)', () {
    test('should default content-Type to octet-stream', () async {
      final app = Pharaoh();

      app.use((req, res, next) {
        final buffer = Uint8List.fromList(utf8.encode("Hello World"));
        next(res.send(buffer));
      });

      await (await request<Pharaoh>(app))
          .get('/')
          .expectStatus(200)
          .expectBody('Hello World')
          .expectContentType('application/octet-stream')
          .test();
    });

    test('should not override previous Content-Types', () async {
      final app = Pharaoh()
        ..get('/html', (req, res) {
          return res.type(ContentType.html).send("<p>Hey</p>");
        })
        ..get('/text', (req, res) {
          return res.type(ContentType.text).send("Hey");
        });

      final tester = await request<Pharaoh>(app);

      await tester
          .get('/html')
          .expectContentType('text/html; charset=utf-8')
          .test();

      await tester
          .get('/text')
          .expectContentType('text/plain; charset=utf-8')
          .test();
    });
  });
}
