import 'dart:async';
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
    this.setFunc,
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
    group('genId option', () {
      test('should provide default generator', () async {
        final app = Pharaoh()
          ..use(session(secret: 'foo bar fuz'))
          ..get('/', (req, res) => res.end());

        await (await request<Pharaoh>(app))
            .get('/')
            .expectStatus(200)
            .expectHeader(HttpHeaders.setCookieHeader, contains(Session.name))
            .test();
      });

      test('should allow custom function', () async {
        final app = Pharaoh()
          ..use(session(secret: 'foo bar fuz', genId: (req) => 'mangoes'))
          ..get('/', (req, res) => res.end());

        await (await request<Pharaoh>(app))
            .get('/')
            .expectStatus(200)
            .expectHeader(HttpHeaders.setCookieHeader,
                'pharaoh.sid=s%3Amangoes.%2FzlbPOSKac8qYzE9mPC0sqTS1L8WgBKVoGk2awh2GZg; Path=/; HttpOnly')
            .test();
      });
    });

    group('name option', () {
      test('should default to pharaoh.sid', () async {
        final app = Pharaoh()
          ..use(session(secret: 'foo bar fuz'))
          ..get('/', (req, res) => res.end());

        await (await request<Pharaoh>(app))
            .get('/')
            .expectStatus(200)
            .expectHeader(HttpHeaders.setCookieHeader, contains(Session.name))
            .test();
      });

      test('should set the cookie name', () async {
        final app = Pharaoh()
          ..use(session(secret: 'foo bar fuz', name: 'session_id'))
          ..get('/', (req, res) => res.end());

        await (await request<Pharaoh>(app))
            .get('/')
            .expectStatus(200)
            .expectHeader(HttpHeaders.setCookieHeader, contains('session_id='))
            .test();
      });
    });

    test('should do nothing if req.session exists', () async {
      final app = Pharaoh()
        ..use((req, res, next) {
          final session = Session('id')..cookie = bakeCookie('phar', 'adf', CookieOpts());
          req[RequestContext.session] = session;

          next((req));
        }.chain(session(secret: '')))
        ..get('/', (req, res) => res.end());

      await (await request<Pharaoh>(app))
          .get('/')
          .expectBody('')
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

    test('should use secret from cookie options if provided', () async {
      const opts = CookieOpts(secret: 'foo bar baz');
      final app = Pharaoh()
        ..use(session(cookie: opts))
        ..get('/', (req, res) => res.end());

      await (await request<Pharaoh>(app))
          .get('/')
          .expectStatus(200)
          .expectHeader(HttpHeaders.setCookieHeader, contains('pharaoh.sid='))
          .test();
    });

    test('should create a new session', () async {
      final app = Pharaoh()
        ..use(session(secret: 'foo bar baz'))
        ..get('/', (req, res) => res.json(req.session));

      await (await request<Pharaoh>(app))
          .get('/')
          .expectStatus(200)
          .expectHeader(HttpHeaders.setCookieHeader, contains('pharaoh.sid='))
          .expectBody(contains("\"cookie\":\"pharaoh.sid="))
          .test();
    });

    test('should pass session fetch error', () async {
      const opts = CookieOpts(secret: 'foo bar baz');
      final store =
          _$TestStore(getFunc: (_) => throw Exception('Session store not available'));

      final app = Pharaoh()
        ..use(cookieParser(opts: opts))
        ..use(session(cookie: opts, store: store))
        ..get('/', (req, res) => res.end());

      await (await request<Pharaoh>(app))
          .get('/', headers: {
            HttpHeaders.cookieHeader:
                'pharaoh.sid=s%3A4badf56b-ab39-4d77-8992-934c995772da.vqiT1VnWppTRhR2pr4F4vb9Oxrbn67E0n0txjKD0qJ4; Path=/'
          })
          .expectStatus(500)
          .expectBody(
              '{"path":"/","method":"GET","message":"Exception: Session store not available"}')
          .test();
    });

    test('should load session from cookie sid', () async {
      const opts = CookieOpts(secret: 'foo bar baz');
      final store = InMemoryStore();

      final app = Pharaoh()
        ..use(cookieParser(opts: opts))
        ..use(session(cookie: opts, store: store))
        ..get('/', (req, res) {
          req.session?['message'] = 'Hello World';
          return res.ok('Message: ${req.session?['message']}');
        });

      final result = await (await request<Pharaoh>(app)).get('/').actual;
      expect(store.sessions, hasLength(1));

      final headers = result.headers;
      expect(headers, contains(HttpHeaders.setCookieHeader));

      final cookieStr = headers[HttpHeaders.setCookieHeader]!;
      await (await request<Pharaoh>(app))
          .get('/', headers: {HttpHeaders.cookieHeader: cookieStr})
          .expectStatus(200)
          .expectBody('Message: Hello World')
          .test();

      expect(store.sessions, hasLength(1));
    });

    group('saveUninitialized option', () {
      test('should default to true', () async {
        final store = InMemoryStore();
        final app = Pharaoh()
          ..use(session(secret: 'foo bar fuz', store: store))
          ..get('/', (req, res) => res.end());

        await (await request<Pharaoh>(app))
            .get('/')
            .expectStatus(200)
            .expectHeader(HttpHeaders.setCookieHeader, contains(Session.name))
            .test();

        expect(store.sessions, hasLength(1));
      });

      test('should prevent save of uninitialized session', () async {
        final store = InMemoryStore();
        final app = Pharaoh()
          ..use(session(secret: 'foo bar fuz', store: store, saveUninitialized: false))
          ..get('/', (req, res) => res.end());

        await (await request<Pharaoh>(app))
            .get('/')
            .expectStatus(200)
            .expectHeaders(isNot(contains(HttpHeaders.setCookieHeader)))
            .test();

        expect(store.sessions, isEmpty);
      });

      test('should still save modified session', () async {
        final store = InMemoryStore();
        final app = Pharaoh()
          ..use(session(secret: 'foo bar fuz', store: store, saveUninitialized: false))
          ..get('/', (req, res) {
            req.session?['name'] = 'Chima';
            req.session?['world'] = 'World';
            return res.end();
          });

        await (await request<Pharaoh>(app))
            .get('/')
            .expectStatus(200)
            .expectHeaders(contains(HttpHeaders.setCookieHeader))
            .test();

        expect(store.sessions, hasLength(1));
      });

      test('should pass session save error', () async {
        final store = _$TestStore(
          getFunc: (_) => throw Exception('Oh hell no'),
          setFunc: (_, __) => throw Exception('Boom shakalaka'),
        );
        final app = Pharaoh()
          ..use(session(secret: 'foo bar fuz', store: store, saveUninitialized: false))
          ..get('/', (req, res) {
            req.session?['name'] = 'Chima';
            req.session?['world'] = 'World';

            return res.end();
          });

        await (await request<Pharaoh>(app))
            .get('/')
            .expectStatus(500)
            .expectBody(
                '{"path":"/","method":"GET","message":"Exception: Boom shakalaka"}')
            .test();
      });
    });

    group('rolling option', () {
      test(
        'should not force cookie on uninitialized session if saveUninitialized option is set to false',
        () async {
          final store = InMemoryStore();

          final opts = CookieOpts(secret: 'foo bar fuz');

          final app = Pharaoh()
            ..use(cookieParser(opts: opts))
            ..use(session(
                cookie: opts, store: store, rolling: true, saveUninitialized: false))
            ..get('/', (req, res) => res.end());

          await (await request<Pharaoh>(app))
              .get('/')
              .expectStatus(200)
              .expectHeaders(isNot(contains(HttpHeaders.setCookieHeader)))
              .test();

          expect(store.sessions, isEmpty);
        },
      );

      test(
        'should force cookie and save uninitialized session if saveUninitialized option is set to true',
        () async {
          final store = InMemoryStore();

          final opts = CookieOpts(secret: 'foo bar fuz');

          final app = Pharaoh()
            ..use(cookieParser(opts: opts))
            ..use(session(
                cookie: opts, store: store, rolling: true, saveUninitialized: true))
            ..get('/', (req, res) => res.end());

          await (await request<Pharaoh>(app))
              .get('/')
              .expectStatus(200)
              .expectHeaders(contains(HttpHeaders.setCookieHeader))
              .test();

          expect(store.sessions, hasLength(1));
        },
      );

      test(
        'should force cookie and save modified session even if saveUninitialized option is set to false',
        () async {
          final store = InMemoryStore();

          final opts = CookieOpts(secret: 'foo bar fuz');

          final app = Pharaoh()
            ..use(cookieParser(opts: opts))
            ..use(session(
                cookie: opts, store: store, rolling: true, saveUninitialized: false))
            ..get('/', (req, res) {
              req.session?['name'] = 'codekeyz';
              return res.end();
            });

          await (await request<Pharaoh>(app))
              .get('/')
              .expectStatus(200)
              .expectHeaders(contains(HttpHeaders.setCookieHeader))
              .test();

          expect(store.sessions, hasLength(1));
        },
      );
    });
  });
}
