import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:pharaoh/pharaoh.dart';
import 'package:spookie/spookie.dart';

class _$TestStore implements SessionStore {
  FutureOr<void> Function()? clearFunc;
  FutureOr<void> Function(String id)? destroyFunc;
  FutureOr<Session?> Function(String id)? getFunc;
  FutureOr<void> Function(String id, Session session)? setFunc;
  FutureOr<List<Session>> Function()? sessionsFunc;

  _$TestStore({
    this.getFunc,
  });
  @override
  FutureOr<void> clear() => clearFunc?.call();

  @override
  FutureOr<void> destroy(String sessionId) => destroyFunc?.call(sessionId);

  @override
  FutureOr<Session?> get(String sessionId) => getFunc?.call(sessionId);

  @override
  FutureOr<List<Session>> get sessions async {
    return await sessionsFunc?.call() ?? [];
  }

  @override
  FutureOr<void> set(String sessionId, Session value) => setFunc?.call(
        sessionId,
        value,
      );
}

void main() {
  group('session_middleware', () {
    test('should do nothing if req.session exists', () async {
      final app = Pharaoh()
          .use((req, res, next) {
            req[RequestContext.session] = Session('id');
            next((req));
          })
          .use(session(secret: ''))
          .get('/', (req, res) => res.end());

      await (await request(app))
          .get('/')
          .expectStatus(200)
          .expectHeaders(isNot(contains(HttpHeaders.setCookieHeader)))
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
          .get('/', (req, res) => res.end());

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

    test('should load session from cookie sid', () async {
      const opts = CookieOpts(secret: 'foo bar baz');
      final store = InMemoryStore();

      final app = Pharaoh()
          .use(cookieParser(opts: opts))
          .use(session(cookie: opts, store: store, saveUninitialized: true))
          .get('/', (req, res) => res.json(req.session));

      final result = await (await request(app)).get('/').actual;
      expect(store.sessions, hasLength(1));

      final headers = result.headers;
      expect(headers, contains(HttpHeaders.setCookieHeader));
      final cookieStr = headers[HttpHeaders.setCookieHeader]!;
      final cookie = Cookie.fromSetCookieValue(cookieStr);

      await (await request(app))
          .get('/', headers: {HttpHeaders.cookieHeader: cookie.toString()})
          .expectStatus(200)
          .expectBodyCustom(
            (body) =>
                Cookie.fromSetCookieValue(jsonDecode(body)['cookie']).value,
            cookie.value,
          )
          .expectHeaders(isNot(contains(HttpHeaders.setCookieHeader)))
          .test();

      expect(store.sessions, hasLength(1));
    });

    test('should pass session fetch error', () async {
      const opts = CookieOpts(secret: 'foo bar baz');
      final store = _$TestStore(
          getFunc: (_) => throw Exception('Session store not available'));

      final app = Pharaoh()
          .use(cookieParser(opts: opts))
          .use(session(cookie: opts, store: store))
          .get('/', (req, res) => res.end());

      await (await request(app))
          .get('/', headers: {
            HttpHeaders.cookieHeader:
                'pharaoh.sid=s%3A4badf56b-ab39-4d77-8992-934c995772da.vqiT1VnWppTRhR2pr4F4vb9Oxrbn67E0n0txjKD0qJ4; Path=/'
          })
          .expectStatus(500)
          .expectBody(
              '{"path":"/","method":"GET","message":"Exception: Session store not available"}')
          .test();
    });

    /// TODO(codekeyz) finish tests for this
    group('when sid not in store', () {});
  });
}