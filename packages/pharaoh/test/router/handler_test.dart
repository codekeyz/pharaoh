import 'package:pharaoh/src/core.dart';
import 'package:pharaoh/src/http/request.dart';
import 'package:spookie/spookie.dart';

void main() {
  group('route_handler', () {
    test('should deliver :req', () async {
      final app = Pharaoh().use(
        (req, res, next) {
          req[RequestContext.auth] = 'some-token';
          return next(req);
        },
      ).get('/', (req, res) => res.send(req.auth));

      await (await request(app))
          .get('/')
          .expectStatus(200)
          .expectBody('some-token')
          .test();
    });

    test('should deliver res', () async {
      final app = Pharaoh().use(
        (req, res, next) {
          req[RequestContext.auth] = 'some-token';
          return next(res.ok('Hello World'));
        },
      );

      await (await request(app))
          .get('/')
          .expectStatus(200)
          .expectBody('Hello World')
          .test();
    });

    test('should deliver both :res and res', () async {
      final app = Pharaoh().use(
        (req, res, next) {
          req[RequestContext.auth] = 'World';
          return next((req: req, res: res.cookie('name', 'tobi')));
        },
      ).get('/', (req, res) => res.ok('Hello ${req.auth}'));

      await (await request(app))
          .get('/')
          .expectHeader('set-cookie', 'name=tobi; Path=/')
          .expectStatus(200)
          .expectBody('Hello World')
          .test();
    });

    test('should deliver both :res and res', () async {
      final app = Pharaoh().use(
        (req, res, next) {
          req[RequestContext.auth] = 'World';
          return next((req: req, res: res.cookie('name', 'tobi')));
        },
      ).get('/', (req, res) => res.ok('Hello ${req.auth}'));

      await (await request(app))
          .get('/')
          .expectHeader('set-cookie', 'name=tobi; Path=/')
          .expectStatus(200)
          .expectBody('Hello World')
          .test();
    });
  });
}
