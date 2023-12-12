import 'package:pharaoh/pharaoh.dart';
import 'package:spookie/spookie.dart';

void main() {
  group('pharaoh_core', () {
    test('should initialize without onError callback', () async {
      final app = Pharaoh()
        ..get('/', (req, res) => throw ArgumentError('Some weird error'));

      await (await request(app))
          .get('/')
          .expectStatus(500)
          .expectBody({'error': "Invalid argument(s): Some weird error"}).test();
    });

    test('should use onError callback if provided', () async {
      final app = Pharaoh()
        ..onError((error, req) =>
            Response.new(statusCode: 500).ok('An error occurred just now'))
        ..get('/', (req, res) => throw ArgumentError('Some weird error'));

      await (await request(app))
          .get('/')
          .expectStatus(500)
          .expectBody('An error occurred just now')
          .test();
    });
  });
}
