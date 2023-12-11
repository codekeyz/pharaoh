import 'dart:io';

import 'package:pharaoh/pharaoh.dart';
import 'package:spookie/spookie.dart';

void main() {
  group('res.cookie(name, string)', () {
    test('should set a cookie', () async {
      final app = Pharaoh()..get('/', (req, res) => res.cookie('name', 'chima').end());

      await (await request<Pharaoh>(app))
          .get('/')
          .expectStatus(200)
          .expectHeader(HttpHeaders.setCookieHeader, 'name=chima; Path=/')
          .test();
    });

    test('should allow multiple calls', () async {
      final app = Pharaoh()
        ..get(
            '/',
            (req, res) => res
                .cookie('name', 'chima')
                .cookie('age', '1')
                .cookie('gender', '?')
                .end());

      await (await request<Pharaoh>(app))
          .get('/')
          .expectStatus(200)
          .expectHeader(HttpHeaders.setCookieHeader,
              'name=chima; Path=/,age=1; Path=/,gender=%3F; Path=/')
          .test();
    });
  });

  group('res.cookie(name, string, {...options})', () {
    test('should set :httpOnly or :secure', () async {
      final app = Pharaoh()
        ..get('/', (req, res) {
          return res
              .cookie('name', 'chima', CookieOpts(httpOnly: true, secure: true))
              .end();
        });

      await (await request<Pharaoh>(app))
          .get('/')
          .expectStatus(200)
          .expectHeader(
              HttpHeaders.setCookieHeader, 'name=chima; Path=/; Secure; HttpOnly')
          .test();
    });

    test('should set :maxAge', () async {
      final app = Pharaoh()
        ..get('/', (req, res) {
          return res
              .cookie('name', 'chima', CookieOpts(maxAge: const Duration(seconds: 5)))
              .end();
        });

      await (await request<Pharaoh>(app))
          .get('/')
          .expectStatus(200)
          .expectHeader(HttpHeaders.setCookieHeader, contains('Max-Age=5;'))
          .expectHeader(HttpHeaders.setCookieHeader, contains('Expires='))
          .test();
    });

    test('should set :signed', () async {
      final app = Pharaoh()
        ..get('/', (req, res) {
          return res
              .cookie('user', {"name": 'tobi'},
                  CookieOpts(signed: true, secret: 'foo bar baz'))
              .end();
        });

      await (await request<Pharaoh>(app))
          .get('/')
          .expectStatus(200)
          .expectHeader(HttpHeaders.setCookieHeader,
              'user=s%3Aj%3A%7B%22name%22%3A%22tobi%22%7D.K20xcwmDS%2BPb1rsD95o5Jm5SqWs1KteqdnynnB7jkTE; Path=/')
          .test();
    });

    test('should reject when :signed without :secret', () async {
      final app = Pharaoh()
        ..get(
            '/',
            (req, res) =>
                res.cookie('user', {"name": 'tobi'}, CookieOpts(signed: true)).end());

      await (await request<Pharaoh>(app))
          .get('/')
          .expectStatus(500)
          .expectBody(contains('CookieOpts(\\"secret\\") required for signed cookies'))
          .test();
    });
  });
}
