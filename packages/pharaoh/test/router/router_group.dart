import 'dart:convert';

import 'package:pharaoh/pharaoh.dart';
import 'package:spookie/spookie.dart';

void main() {
  group('router', () {
    test('should execute middlewares in group', () async {
      final app = Pharaoh()..post('/', (req, res) => res.ok(req.body));

      final adminRouter = app
        ..router().get('/', (req, res) => res.ok('Holy Moly 🚀'))
        ..post('/hello', (req, res) => res.ok(req.body));
      app.group('/admin', adminRouter);

      await (await request(app))
          .post('/', jsonEncode({'_': 'Hello World 🚀'}))
          .expectBody('{"_":"Hello World 🚀"}')
          .expectStatus(200)
          .test();

      await (await request(app))
          .post('/admin/hello', jsonEncode({'_': 'Hello World 🚀'}))
          .expectBody('{"_":"Hello World 🚀"}')
          .expectStatus(200)
          .test();

      await (await request(app))
          .get('/admin')
          .expectBody('Holy Moly 🚀')
          .expectStatus(200)
          .test();
    });
  });
}
