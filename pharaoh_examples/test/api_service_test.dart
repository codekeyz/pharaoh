import 'dart:io';

import 'package:pharaoh_examples/api_service/index.dart' as apisvc;
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() async {
  group('api_service_example', () {
    setUpAll(() => Future.sync(() => apisvc.main()));

    tearDownAll(() => apisvc.app.shutdown());

    group('should return json error message', () {
      test('when `api-key` not provided', () async {
        final serverUrl = apisvc.app.uri.toString();
        final path = Uri.parse('$serverUrl/api/users');

        final result = await http.get(path);
        expect(result.statusCode, 400);
        expect(
          result.headers[HttpHeaders.contentTypeHeader],
          'application/json; charset=utf-8',
        );
        expect(result.body, '"API key required"');
      });

      test('when `api-key` is invalid', () async {
        final serverUrl = apisvc.app.uri.toString();
        final path = Uri.parse('$serverUrl/api/users?api-key=asfas');

        final result = await http.get(path);
        expect(result.statusCode, 401);
        expect(
          result.headers[HttpHeaders.contentTypeHeader],
          'application/json; charset=utf-8',
        );
        expect(result.body, '"Invalid API key"');
      });
    });

    group('when `api-key` is provided and valid', () {
      test('should return users', () async {
        final serverUrl = apisvc.app.uri.toString();
        final path = Uri.parse('$serverUrl/api/users?api-key=foo');

        final result = await http.get(path);
        expect(result.statusCode, 200);
        expect(
          result.headers[HttpHeaders.contentTypeHeader],
          'application/json; charset=utf-8',
        );
        expect(
          result.body,
          '[{"name":"tobi"},{"name":"loki"},{"name":"jane"}]',
        );
      });

      group('and route is get repos for :name', () {
        test('should return repos when found', () async {
          final serverUrl = apisvc.app.uri.toString();
          final path = Uri.parse('$serverUrl/api/user/tobi/repos?api-key=foo');

          final result = await http.get(path);
          expect(result.statusCode, 200);
          expect(
            result.headers[HttpHeaders.contentTypeHeader],
            'application/json; charset=utf-8',
          );
          expect(
            result.body,
            '[{"name":"express","url":"https://github.com/expressjs/express"},{"name":"stylus","url":"https://github.com/learnboost/stylus"}]',
          );
        });

        test('should return notFound when :name not found', () async {
          final serverUrl = apisvc.app.uri.toString();
          final path = Uri.parse('$serverUrl/api/user/chima/repos?api-key=foo');

          final result = await http.get(path);
          expect(result.statusCode, 404);
          expect(
            result.headers[HttpHeaders.contentTypeHeader],
            'application/json; charset=utf-8',
          );
          expect(
            result.body,
            '{"path":"/api/user/chima/repos","method":"GET","message":"Not found"}',
          );
        });
      });

      test('should return repos', () async {
        final serverUrl = apisvc.app.uri.toString();
        final path = Uri.parse('$serverUrl/api/repos?api-key=foo');

        final result = await http.get(path);
        expect(result.statusCode, 200);
        expect(
          result.headers[HttpHeaders.contentTypeHeader],
          'application/json; charset=utf-8',
        );
        expect(
          result.body,
          '[{"name":"express","url":"https://github.com/expressjs/express"},{"name":"stylus","url":"https://github.com/learnboost/stylus"},{"name":"cluster","url":"https://github.com/learnboost/cluster"}]',
        );
      });
    });
  });
}
