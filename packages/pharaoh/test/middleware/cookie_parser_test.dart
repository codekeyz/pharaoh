import 'dart:io';

import 'package:pharaoh/src/core.dart';
import 'package:pharaoh/src/http/cookie.dart';
import 'package:pharaoh/src/middleware/cookie_parser.dart';
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
            .get('/', headers: {
              HttpHeaders.cookieHeader:
                  'name=s%3Achima.4ytL9j25i8e59B6eCUUZdrWHdGLK3Cua%2BG1oGyurzXY'
            })
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
              HttpHeaders.cookieHeader:
                  'name=s%3Achimaxyz.4ytL9j25i8e59B6eCUUZdrWHdGLK3Cua%2BG1oGyurzXY; Path=/'
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

        await (await request<Pharaoh>(app))
            .get('/')
            .expectStatus(200)
            .expectBody('[]')
            .test();
      });

      test('should default req.signedCookies to []', () async {
        final app = Pharaoh()
          ..use(cookieParser())
          ..get('/', (req, res) {
            final str = req.signedCookies.toString();
            return res.ok(str);
          });

        await (await request<Pharaoh>(app))
            .get('/')
            .expectStatus(200)
            .expectBody('[]')
            .test();
      });
    });
  });
}
