import 'package:pharaoh/pharaoh.dart';
import 'package:spookie/spookie.dart';

void main() {
  group('res.status(code)', () {
    group('should set the response status code', () {
      test('when "code" is 201 to 201', () async {
        final app = Pharaoh()
          ..use(
            (req, res, next) => next(res.status(201).end()),
          );

        await (await request<Pharaoh>(app)).get('/').expectStatus(201).test();
      });

      test('when "code" is 400 to 400', () async {
        final app = Pharaoh()
          ..use((req, res, next) {
            res = res.status(400).end();
            next(res);
          });

        await (await request<Pharaoh>(app)).get('/').expectStatus(400).test();
      });

      test('when "code" is 500 to 500', () async {
        final app = Pharaoh()
          ..use((req, res, next) {
            res = res.status(500).end();
            next(res);
          });

        await (await request<Pharaoh>(app)).get('/').expectStatus(500).test();
      });
    });

    group("should throw error", () {
      test('when "code" is 302 without location', () async {
        final app = Pharaoh()
          ..use((req, res, next) {
            res = res.status(302).end();
            next(res);
          });

        try {
          await (await request<Pharaoh>(app)).get('/').test();
        } catch (e) {
          expect(
              (e as StateError).message, 'Response has no Location header for redirect');
        }
      });
    });
  });
}
