import 'dart:io';

import 'package:pharaoh/pharaoh.dart';
import 'package:spookie/spookie.dart';

void main() {
  group('cookieParser', () {
    group('when cookies are sent', () {
      test('should populate req.cookies', () async {
        final app = Pharaoh()
          ..use(cookieParser())
          ..get('/', (req, res) {
            final str = req.cookies.toString();
            return res.ok(str);
          });

        await (await request(app))
            .get('/', headers: {HttpHeaders.cookieHeader: 'foo=bar; bar=baz'})
            .expectStatus(200)
            .expectBody('[foo=bar; HttpOnly, bar=baz; HttpOnly]')
            .test();
      });

      test('should populate req.signedCookies', () async {
        const opts = CookieOpts(secret: 'foo bar baz', signed: true);
        final app = Pharaoh()
          ..use(cookieParser(opts: opts))
          ..get('/', (req, res) {
            final str = req.signedCookies.toString();
            return res.ok(str);
          });

        await (await request(app))
            .get('/',
                headers: {HttpHeaders.cookieHeader: 'name=s%3Achima.4ytL9j25i8e59B6eCUUZdrWHdGLK3Cua%2BG1oGyurzXY'})
            .expectStatus(200)
            .expectBody('[name=chima; HttpOnly]')
            .test();
      });

      test('should remove tampered signed cookies', () async {
        const opts = CookieOpts(secret: 'foo bar baz', signed: true);
        final app = Pharaoh()
          ..use(cookieParser(opts: opts))
          ..get('/', (req, res) {
            final str = req.signedCookies.toString();
            return res.ok(str);
          });

        await (await request(app))
            .get('/', headers: {
              HttpHeaders.cookieHeader: 'name=s%3Achimaxyz.4ytL9j25i8e59B6eCUUZdrWHdGLK3Cua%2BG1oGyurzXY; Path=/'
            })
            .expectStatus(200)
            .expectBody('[]')
            .test();
      });

      test('should leave unsigned cookies as they are', () async {
        const opts = CookieOpts(secret: 'foo bar baz', signed: true);
        final app = Pharaoh()
          ..use(cookieParser(opts: opts))
          ..get('/', (req, res) {
            final str = req.cookies.toString();
            return res.ok(str);
          });

        await (await request(app))
            .get('/', headers: {HttpHeaders.cookieHeader: 'name=chima; Path=/'})
            .expectStatus(200)
            .expectBody('[name=chima; HttpOnly, Path=/; HttpOnly]')
            .test();
      });
    });

    group('when no cookies are sent', () {
      test('should default req.cookies to []', () async {
        final app = Pharaoh()
          ..use(cookieParser())
          ..get('/', (req, res) {
            final str = req.cookies.toString();
            return res.ok(str);
          });

        await (await request<Pharaoh>(app)).get('/').expectStatus(200).expectBody('[]').test();
      });

      test('should default req.signedCookies to []', () async {
        final app = Pharaoh()
          ..use(cookieParser())
          ..get('/', (req, res) {
            final str = req.signedCookies.toString();
            return res.ok(str);
          });

        await (await request<Pharaoh>(app)).get('/').expectStatus(200).expectBody('[]').test();
      });
    });

    group('when json-encoded value', () {
      test('should parse when signed', () async {
        final cookieOpts = CookieOpts(signed: true, secret: 'foo-bar-mee-moo');
        final cookie = bakeCookie('user', {'foo': 'bar', 'mee': 'mee'}, cookieOpts);

        expect(cookie.toString(),
            'user=s%3Aj%3A%7B%22foo%22%3A%22bar%22%2C%22mee%22%3A%22mee%22%7D.sxYOqZyRsCeSGNGzAR5UG3Hv%2BW%2BiXl9TQPlbbdBLMF0; Path=/');

        expect(cookie.signed, isTrue);

        expect(cookie.jsonEncoded, isTrue);

        final app = Pharaoh()
          ..use(cookieParser(opts: cookieOpts))
          ..get('/', (req, res) => res.json(req.signedCookies.first.actualObj));

        await (await request(app))
            .get('/', headers: {HttpHeaders.cookieHeader: cookie.toString()})
            .expectStatus(200)
            .expectJsonBody({'foo': 'bar', 'mee': 'mee'})
            .test();
      });

      test('should parse when un-signed', () async {
        final cookieOpts = CookieOpts(signed: false);
        final cookie = bakeCookie('user', {'foo': 'bar', 'mee': 'mee'}, cookieOpts);

        expect(cookie.toString(), 'user=j%3A%7B%22foo%22%3A%22bar%22%2C%22mee%22%3A%22mee%22%7D; Path=/');

        expect(cookie.signed, isFalse);

        expect(cookie.jsonEncoded, isTrue);

        final app = Pharaoh()
          ..use(cookieParser(opts: cookieOpts))
          ..get('/', (req, res) => res.json(req.cookies.first.actualObj));

        await (await request(app))
            .get('/', headers: {HttpHeaders.cookieHeader: cookie.toString()})
            .expectStatus(200)
            .expectJsonBody({'foo': 'bar', 'mee': 'mee'})
            .test();
      });
    });
  });
}
