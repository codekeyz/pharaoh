import 'package:pharaoh/pharaoh.dart';
import 'package:spookie/spookie.dart';

void main() {
  group('route_handler', () {
    test('should deliver :req', () async {
      final app = Pharaoh()
        ..use((req, res, next) {
          req[RequestContext.auth] = 'some-token';
          return next(req);
        })
        ..get('/', (req, res) => res.send(req.auth));

      await (await request<Pharaoh>(app))
          .get('/')
          .expectStatus(200)
          .expectBody('some-token')
          .test();
    });

    test('should deliver res', () async {
      final app = Pharaoh()
        ..use((req, res, next) {
          req[RequestContext.auth] = 'some-token';
          return next(res.ok('Hello World'));
        });

      await (await request<Pharaoh>(app))
          .get('/')
          .expectStatus(200)
          .expectBody('Hello World')
          .test();
    });

    test('should deliver both :res and res', () async {
      final app = Pharaoh()
        ..use((req, res, next) {
          req[RequestContext.auth] = 'World';
          return next((req: req, res: res.cookie('name', 'tobi')));
        })
        ..get('/', (req, res) => res.ok('Hello ${req.auth}'));

      await (await request<Pharaoh>(app))
          .get('/')
          .expectHeader('set-cookie', 'name=tobi; Path=/')
          .expectStatus(200)
          .expectBody('Hello World')
          .test();
    });

    test('should deliver both :res and res', () async {
      final app = Pharaoh()
        ..use((req, res, next) {
          req[RequestContext.auth] = 'World';
          return next((req: req, res: res.cookie('name', 'tobi')));
        })
        ..get('/', (req, res) => res.ok('Hello ${req.auth}'));

      await (await request(app))
          .get('/')
          .expectHeader('set-cookie', 'name=tobi; Path=/')
          .expectStatus(200)
          .expectBody('Hello World')
          .test();
    });

    test('should chain middlewares in the right order', () async {
      final listResultList = <int>[];

      final Middleware mdw1 = (req, res, next) {
        listResultList.add(1);
        next();
      };

      final Middleware mdw2 = (req, res, next) {
        listResultList.add(2);
        next();
      };

      final Middleware mdw3 = (req, res, next) {
        listResultList.add(3);
        next();
      };

      Pharaoh getApp(Middleware chain) {
        final app = Pharaoh();
        return app
          ..use(chain)
          ..get('/test', (req, res) => res.ok());
      }

      final testChain1 = mdw1.chain(mdw2).chain(mdw3);
      await (await request(getApp(testChain1))).get('/test').test();
      expect(listResultList, [1, 2, 3]);

      listResultList.clear();

      final testChain2 = mdw2.chain(mdw1).chain(mdw3);
      await (await request(getApp(testChain2))).get('/test').test();
      expect(listResultList, [2, 1, 3]);

      listResultList.clear();

      final testChain3 = mdw3.chain(mdw1.chain(mdw3)).chain(mdw2.chain(mdw1));
      await (await request(getApp(testChain3))).get('/test').test();
      expect(listResultList, [3, 1, 3, 2, 1]);

      listResultList.clear();

      final complexChain = testChain3.chain(testChain1).chain(testChain2);
      await (await request(getApp(complexChain))).get('/test').test();
      expect(listResultList, [3, 1, 3, 2, 1, 1, 2, 3, 2, 1, 3]);

      listResultList.clear();

      final shortLivedChain =
          testChain3.chain((req, res, next) => next(res.end())).chain(testChain2);

      await (await request(getApp(shortLivedChain))).get('/test').test();
      expect(listResultList, [3, 1, 3, 2, 1]);
    });
  });
}
