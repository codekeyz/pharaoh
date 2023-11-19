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

      test('should reject on missing header', () async {
        final result = await (await request<Pharaoh>(app)).get(endpoint);
        expect(result.statusCode, 401);
        expect(result.body, '"Username & password is required!"');
      });

      test('should reject on wrong credentials', () async {
        final result = await (await request<Pharaoh>(app))
            .auth('dude', 'stuff')
            .get(endpoint);
        expect(result.statusCode, 401);
      });

      test('should reject on shorter prefix', () async {
        final result = await (await request<Pharaoh>(app))
            .auth('Admin', 'secret')
            .get(endpoint);
        expect(result.statusCode, 401);
      });

      test('should reject without challenge', () async {
        final result = await (await request<Pharaoh>(app))
            .auth('dude', 'stuff')
            .get(endpoint);
        expect(result.statusCode, 401);
        expect(result.headers['WWW-Authenticate'], isNull);
      });

      test('should accept correct credentials', () async {
        final result = await (await request<Pharaoh>(app))
            .auth('Admin', 'secret1234')
            .get(endpoint);
        expect(result.statusCode, 200);
      });
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

      test('should reject on missing header', () async {
        final result = await (await request<Pharaoh>(app)).get(endpoint);
        expect(result.statusCode, 401);
      });

      test('should reject on wrong credentials', () async {
        final result = await (await request<Pharaoh>(app))
            .auth('dude', 'stuff')
            .get(endpoint);
        expect(result.statusCode, 401);
        expect(result.body, '"Ohmygod, credentials is required!"');
      });

      test('should accept fitting credentials', () async {
        final result = await (await request<Pharaoh>(app))
            .auth('Aloha', 'secretverymuch')
            .get(endpoint);
        expect(result.statusCode, 200);
        expect(result.body, 'You passed');
      });

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

        test('should reject wrong credentials', () async {
          final result = await (await request<Pharaoh>(app))
              .auth('bla', 'blub')
              .get(endpoint);
          expect(result.statusCode, 401);
        });

        test('should accept fitting credentials', () async {
          final result = await (await request<Pharaoh>(app))
              .auth('Testeroni', 'testsecret')
              .get(endpoint);
          expect(result.statusCode, 200);
          expect(result.body, 'You passed');
        });
      });
    });
  });
}
