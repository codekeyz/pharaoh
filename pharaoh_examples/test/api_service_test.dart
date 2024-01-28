import 'package:pharaoh_examples/api_service/index.dart' as apisvc;
import 'package:spookie/spookie.dart';

void main() async {
  group('api_service_example', () {
    late Spookie appTester;

    setUpAll(() async {
      apisvc.main([0]);
      appTester = await request(apisvc.app);
    });

    tearDownAll(() => apisvc.app.shutdown());

    group('should return json error message', () {
      test('when `api-key` not provided', () async {
        await appTester
            .get('/api/users')
            .expectStatus(400)
            .expectJsonBody('API key required')
            .test();
      });

      test('when `api-key` is invalid', () async {
        await appTester
            .get('/api/users?api-key=asfas')
            .expectStatus(401)
            .expectJsonBody('Invalid API key')
            .test();
      });
    });

    group('when `api-key` is provided and valid', () {
      test('should return users', () async {
        final result = [
          {'name': 'tobi'},
          {'name': 'loki'},
          {'name': 'jane'}
        ];

        await appTester
            .get('/api/users?api-key=foo')
            .expectStatus(200)
            .expectJsonBody(result)
            .test();
      });

      group('and route is get repos for :name', () {
        test('should return repos when found', () async {
          const result = [
            {'name': 'express', 'url': "https://github.com/expressjs/express"},
            {'name': 'stylus', 'url': "https://github.com/learnboost/stylus"},
          ];

          await appTester
              .get('/api/user/tobi/repos?api-key=foo')
              .expectStatus(200)
              .expectJsonBody(result)
              .test();
        });

        test('should return notFound when :name not found', () async {
          await appTester
              .get('/api/user/chima/repos?api-key=foo')
              .expectStatus(404)
              .expectJsonBody({"error": "Not found"}).test();
        });
      });

      test('should return repos', () async {
        const result = [
          {'name': 'express', 'url': "https://github.com/expressjs/express"},
          {'name': 'stylus', 'url': "https://github.com/learnboost/stylus"},
          {'name': 'cluster', 'url': "https://github.com/learnboost/cluster"},
        ];

        await appTester
            .get('/api/repos?api-key=foo')
            .expectStatus(200)
            .expectJsonBody(result)
            .test();
      });
    });
  });
}
