import 'dart:io';

import 'package:pharaoh_examples/api_service/index.dart' as apisvc;
import 'package:spookie/spookie.dart';

void main() async {
  group('api_service_example', () {
    setUpAll(() => Future.sync(() => apisvc.main([0])));

    tearDownAll(() => apisvc.app.shutdown());

    group('should return json error message', () {
      test('when `api-key` not provided', () async {
        await (await request(apisvc.app))
            .get('/api/users')
            .expectStatus(400)
            .expectHeader(
                HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8')
            .expectBody('"API key required"')
            .test();
      });

      test('when `api-key` is invalid', () async {
        await (await request(apisvc.app))
            .get('/api/users?api-key=asfas')
            .expectStatus(401)
            .expectHeader(
                HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8')
            .expectBody('"Invalid API key"')
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

        await (await request(apisvc.app))
            .get('/api/users?api-key=foo')
            .expectStatus(200)
            .expectHeader(
                HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8')
            .expectBody(result)
            .test();
      });

      group('and route is get repos for :name', () {
        test('should return repos when found', () async {
          const result = [
            {'name': 'express', 'url': "https://github.com/expressjs/express"},
            {'name': 'stylus', 'url': "https://github.com/learnboost/stylus"},
          ];

          await (await request(apisvc.app))
              .get('/api/user/tobi/repos?api-key=foo')
              .expectStatus(200)
              .expectHeader(
                  HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8')
              .expectBody(result)
              .test();
        });

        test('should return notFound when :name not found', () async {
          await (await request(apisvc.app))
              .get('/api/user/chima/repos?api-key=foo')
              .expectStatus(404)
              .expectHeader(
                  HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8')
              .expectBody(
                  '{"path":"/api/user/chima/repos","method":"GET","message":"Not found"}')
              .test();
        });
      });

      test('should return repos', () async {
        const result = [
          {'name': 'express', 'url': "https://github.com/expressjs/express"},
          {'name': 'stylus', 'url': "https://github.com/learnboost/stylus"},
          {'name': 'cluster', 'url': "https://github.com/learnboost/cluster"},
        ];

        await (await request(apisvc.app))
            .get('/api/repos?api-key=foo')
            .expectStatus(200)
            .expectHeader(
                HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8')
            .expectBody(result)
            .test();
      });
    });
  });
}
