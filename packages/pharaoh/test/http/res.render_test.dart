import 'dart:async';

import 'package:pharaoh/pharaoh.dart';
import 'package:spookie/spookie.dart';

class TestViewEngine extends ViewEngine {
  final knownTemplates = ['welcome'];

  @override
  String get name => 'FoobarViewEngine';

  @override
  FutureOr<String> render(String template, Map<String, dynamic> data) {
    if (!knownTemplates.contains(template)) {
      throw Exception('Not found');
    }

    return data.isEmpty
        ? 'Hello World'
        : data.entries.map((e) => '${e.key}:${e.value}').join('\n');
  }
}

void main() {
  late Pharaoh app;

  setUp(() {
    Pharaoh.viewEngine = TestViewEngine();
    app = Pharaoh();
  });

  group('res.render', () {
    test('should render template', () async {
      app = app..get('/', (req, res) => res.render('welcome'));

      await (await request(app))
          .get('/')
          .expectBody('Hello World')
          .expectStatus(200)
          .expectContentType('text/html; charset=utf-8')
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
          .expectBody('username:Spookie')
          .expectContentType('text/html; charset=utf-8')
          .test();
    });

    test('should err when template not found', () async {
      app = app..get('/', (req, res) => res.render('products'));

      await (await request(app))
          .get('/')
          .expectStatus(500)
          .expectContentType('application/json; charset=utf-8')
          .expectJsonBody(containsPair(
            'error',
            "Pharaoh Error: Failed to render view products ---> Instance of \'_Exception\'",
          ))
          .test();
    });

    test('should err when no view engine', () async {
      Pharaoh.viewEngine = null;
      app = app..get('/', (req, res) => res.render('products'));

      await (await request(app))
          .get('/')
          .expectStatus(500)
          .expectJsonBody(containsPair(
            'error',
            'Pharaoh Error(s): No view engine found',
          ))
          .test();
    });
  });
}
