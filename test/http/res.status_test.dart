import 'package:pharaoh/pharaoh.dart';
import 'package:supertest/supertest.dart';
import 'package:test/test.dart';

void main() {
  group('res.status(code)', () {
    group('should set the response status code', () {
      test('when "code" is 201 to 201', () async {
        final app = Pharaoh().use((req, res, next) {
          res = res.status(201).end();
          next(res);
        });

        final result = await (await request<Pharaoh>(app)).get('/');
        expect(result.statusCode, 201);
      });

      test('when "code" is 400 to 400', () async {
        final app = Pharaoh().use((req, res, next) {
          res = res.status(400).end();
          next(res);
        });

        final result = await (await request<Pharaoh>(app)).get('/');
        expect(result.statusCode, 400);
      });

      test('when "code" is 500 to 500', () async {
        final app = Pharaoh().use((req, res, next) {
          res = res.status(500).end();
          next(res);
        });

        final result = await (await request<Pharaoh>(app)).get('/');
        expect(result.statusCode, 500);
      });
    });

    group("should throw error", () {
      test('when "code" is 302 without location', () async {
        final app = Pharaoh().use((req, res, next) {
          res = res.status(302).end();
          next(res);
        });

        try {
          await (await request<Pharaoh>(app)).get('/');
        } catch (e) {
          expect((e as StateError).message,
              'Response has no Location header for redirect');
        }
      });
    });
  });
}
