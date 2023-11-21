import 'package:pharaoh/pharaoh.dart';
import 'package:pharaoh_basic_auth/src/basic_auth.dart';
import 'package:supertest/supertest.dart';
import 'package:test/test.dart';

final app = Pharaoh().get('/', (req, res) => res);

void main() {
  group('pharaoh_basic_auth', () {
    group('safe compare', () {
      test('should return false on different inputs', () {
        expect(safeCompare('asdf', 'rftghe'), false);
      });

      test('should return false on prefix inputs', () {
        expect(safeCompare('some', 'something'), false);
      });

      test('should return true on same inputs', () {
        expect(safeCompare('anothersecret', 'anothersecret'), true);
      });
    });

    group('static users', () {
      late Pharaoh app;
      const endpoint = '/static';

      setUpAll(() {
        // requires basic auth with username 'Admin' and password 'secret1234'
        final staticUserAuth = basicAuth(
          users: {"Admin": "secret1234"},
          challenge: false,
          unauthorizedResponse: (_) => 'Username & password is required!',
        );
        app = Pharaoh()
            .use(staticUserAuth)
            .get(endpoint, (req, res) => res.send('You passed'));
      });

      test(
        'should reject on missing header',
        () async => (await request<Pharaoh>(app))
            .get(endpoint)
            .status(401)
            .body('"Username & password is required!"')
            .test(),
      );

      test(
        'should reject on wrong credentials',
        () async => (await request<Pharaoh>(app))
            .auth('dude', 'stuff')
            .get(endpoint)
            .status(401)
            .test(),
      );

      test(
        'should reject on shorter prefix',
        () async => (await request<Pharaoh>(app))
            .auth('Admin', 'secret')
            .get(endpoint)
            .status(401)
            .test(),
      );

      test(
        'should reject without challenge',
        () async => (await request<Pharaoh>(app))
            .auth('dude', 'stuff')
            .get(endpoint)
            .status(401)
            .header('WWW-Authenticate', isNull)
            .test(),
      );

      test(
        'should accept correct credentials',
        () async => await (await request<Pharaoh>(app))
            .auth('Admin', 'secret1234')
            .get(endpoint)
            .status(200)
            .test(),
      );
    });

    group('custom authorizer', () {
      late Pharaoh app;
      const endpoint = '/custom';

      setUpAll(() {
        // Custom authorizer checking if the username starts with 'A' and the password with 'secret'
        bool myAuthorizer(
          String username,
          String password,
        ) =>
            username.startsWith('A') && password.startsWith('secret');

        final customAuthorizerAuth = basicAuth(
          authorizer: myAuthorizer,
          unauthorizedResponse: (_) => 'Ohmygod, credentials is required!',
        );
        app = Pharaoh()
            .use(customAuthorizerAuth)
            .get(endpoint, (req, res) => res.send('You passed'));
      });

      test(
        'should reject on missing header',
        () async => (await request<Pharaoh>(
          app,
        ))
            .get(endpoint)
            .status(401)
            .test(),
      );

      test(
        'should reject on wrong credentials',
        () async => (await request<Pharaoh>(app))
            .auth('dude', 'stuff')
            .get(endpoint)
            .status(401)
            .body('"Ohmygod, credentials is required!"')
            .test(),
      );

      test(
        'should accept fitting credentials',
        () async => (await request<Pharaoh>(app))
            .auth('Aloha', 'secretverymuch')
            .get(endpoint)
            .status(200)
            .body('You passed')
            .test(),
      );

      group('with safe compare', () {
        const endpoint = '/custom-compare';

        setUp(() {
          bool myComparingAuthorizer(username, password) =>
              safeCompare(username, 'Testeroni') &&
              safeCompare(password, 'testsecret');

          final customAuth = basicAuth(authorizer: myComparingAuthorizer);
          app = Pharaoh()
              .use(customAuth)
              .get(endpoint, (req, res) => res.send('You passed'));
        });

        test(
          'should reject wrong credentials',
          () async => (await request<Pharaoh>(app))
              .auth('bla', 'blub')
              .get(endpoint)
              .status(401)
              .test(),
        );

        test(
          'should accept fitting credentials',
          () async => (await request<Pharaoh>(app))
              .auth('Testeroni', 'testsecret')
              .get(endpoint)
              .status(200)
              .body('You passed')
              .test(),
        );
      });
    });
  });
}
