import 'dart:io';

import 'package:pharaoh/pharaoh.dart';
import 'package:spookie/spookie.dart';

void main() {
  group('session_middleware', () {
    test('should do nothing if req.session exists', () async {
      final app = Pharaoh()
          .use((req, res, next) {
            req[RequestContext.session] = Session('id', store: InMemoryStore());
            next(req);
          })
          .use(session(secret: ''))
          .get('/', (req, res) => res.ok('foo bar'));

      await (await request(app))
          .get('/')
          .expectStatus(200)
          .expectHeaders(
            (hdrs) => !(hdrs as Map).containsKey(HttpHeaders.setCookieHeader),
          )
          .test();
    });

    test(
      'should error without secret',
      () => expect(
        () => Pharaoh().use(session()),
        throwsA(isA<PharaohException>().having(
          (e) => e.message,
          'message',
          'CookieOpts("secret") required for signed cookies',
        )),
      ),
    );

    test('should get secret from cookie options if provided', () async {
      const opts = CookieOpts(secret: 'foo bar baz');
      final app = Pharaoh()
          .use(session(cookie: opts))
          .get('/', (req, res) => res.ok('foo bar'));

      await (await request(app))
          .get('/')
          .expectStatus(200)
          .expectHeader(HttpHeaders.setCookieHeader, contains('pharaoh.sid='))
          .test();
    });

    test('should create a new session', () async {
      final app = Pharaoh()
          .use(session(secret: 'foo bar baz'))
          .get('/', (req, res) => res.json(req.session));

      await (await request(app))
          .get('/')
          .expectStatus(200)
          .expectHeader(HttpHeaders.setCookieHeader, contains('pharaoh.sid='))
          .expectBody(contains("\"cookie\":\"pharaoh.sid="))
          .test();
    });
  });
}
