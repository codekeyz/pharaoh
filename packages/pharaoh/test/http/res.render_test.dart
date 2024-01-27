import 'dart:io';

import 'package:pharaoh/pharaoh.dart';
import 'package:spookie/spookie.dart';

void main() {
  late Pharaoh app;

  setUp(() => app = Pharaoh()
    ..viewEngine = JinjaViewEngine(Environment(
      autoReload: false,
      trimBlocks: true,
      leftStripBlocks: true,
      loader: FileSystemLoader(paths: ['public']),
    )));

  group('res.render', () {
    test('should render template', () async {
      app = app..get('/', (req, res) => res.render('welcome'));

      await (await request(app))
          .get('/')
          .expectBody('Hello ')
          .expectStatus(200)
          .expectContentType(ContentType.html.toString())
          .test();
    });

    test('should render template with variables', () async {
      app = app
        ..get(
          '/',
          (req, res) => res.render('welcome', {'username': 'Spookie'}),
        );

      await (await request(app))
          .get('/')
          .expectStatus(200)
          .expectBody('Hello Spookie')
          .expectContentType(ContentType.html.toString())
          .test();
    });

    test('should err when template not found', () async {
      app = app..get('/', (req, res) => res.render('products'));

      await (await request(app))
          .get('/')
          .expectStatus(404)
          .expectContentType(ContentType.html.toString())
          .expectBody({'error': 'Template `products` not found'}).test();
    });

    test('should err when template not found', () async {
      app = app
        ..viewEngine = null
        ..get('/', (req, res) => res.render('products'));

      await (await request(app))
          .get('/')
          .expectStatus(500)
          .expectJsonBody(
            containsPair('error', 'Pharaoh Error(s): No view engine found'),
          )
          .test();
    });
  });
}
