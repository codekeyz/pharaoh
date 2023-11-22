import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:pharaoh/pharaoh.dart';
import 'package:pharaoh_jwt_auth/pharaoh_jwt_auth.dart';
import 'package:spookie/spookie.dart';

void main() {
  group('pharaoh_jwt_auth', () {
    group('when :authRequired', () {
      late Pharaoh app;
      final secretKey = SecretKey('hello-new-secret');

      setUpAll(() {
        final config = PharaohJwtConfig(
          algorithms: [JWTAlgorithm.HS256],
          secret: Future.value(secretKey),
        );

        app = Pharaoh()
            .use(jwtAuth(config))
            .get('/users/me', (req, res) => res.json(req.auth));
      });

      test(
        'should reject on no authorization header',
        () async => (await request<Pharaoh>(app))
            .get('/users/me')
            .expectStatus(401)
            .expectContentType('application/json; charset=utf-8')
            .expectBodyCustom((body) => jsonDecode(body)['message'],
                'No authorization token was found')
            .test(),
      );

      test(
        'should reject on malformed token',
        () async => (await request<Pharaoh>(app))
            .token('some-random-token')
            .get('/users/me')
            .expectStatus(401)
            .expectBodyCustom((body) => jsonDecode(body)['message'],
                'Format is Authorization: Bearer [token]')
            .test(),
      );

      test(
        'should accept on valid authorization header',
        () async {
          final jwt = JWT(
            {
              'id': 123,
              'server': {
                'id': '3e4fc296',
                'loc': 'euw-2',
              }
            },
            issuer: 'https://github.com/jonasroussel/dart_jsonwebtoken',
          );

          final token = jwt.sign(secretKey);

          await (await request<Pharaoh>(app))
              .token(token)
              .get('/users/me')
              .expectBodyCustom((body) => jsonDecode(body)['id'], 123)
              .expectStatus(200)
              .test();
        },
      );
    });

    group('when :authRequired not required', () {
      late Pharaoh app;
      final secretKey = SecretKey('another-new-secret');

      setUpAll(() {
        final config = PharaohJwtConfig(
          algorithms: [JWTAlgorithm.HS256],
          secret: Future.value(secretKey),
          authRequired: false,
        );

        app = Pharaoh()
            .use(jwtAuth(config))
            .get('/', (req, res) => res.ok('Welcome home'))
            .post('/users', (req, res) => res.json(req.auth));
      });

      test(
        'should accept on no authorization header',
        () async => (await request<Pharaoh>(app))
            .get('/')
            .expectStatus(200)
            .expectBody('Welcome home')
            .test(),
      );

      test(
        'should reject on malformed token',
        () async => (await request<Pharaoh>(app))
            .token('some-random-token')
            .get('/')
            .expectBodyCustom((body) => jsonDecode(body)['message'],
                'Format is Authorization: Bearer [token]')
            .expectStatus(401)
            .test(),
      );

      test(
        'should accept on valid authorization header',
        () async {
          final jwt = JWT(
            {
              'id': 123,
              'server': {
                'id': '3e4fc296',
                'loc': 'euw-2',
              }
            },
            issuer: 'https://github.com/jonasroussel/dart_jsonwebtoken',
          );

          final token = jwt.sign(secretKey);

          await (await request<Pharaoh>(app))
              .token(token)
              .post('/users', {})
              .expectStatus(200)
              .expectBodyCustom((body) => jsonDecode(body)['id'], 123)
              .test();
        },
      );
    });
  });
}
