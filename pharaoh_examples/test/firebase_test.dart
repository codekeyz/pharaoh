import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dart_firebase_admin/auth.dart';
import 'package:pharaoh_examples/firebase/domain/models/todo.model.dart';
import 'package:pharaoh_examples/firebase/handlers/handler.utils.dart';
import 'package:pharaoh_examples/firebase/index.dart' as apisvc;
import 'package:spookie/spookie.dart';

void main() {
  group('firebase_example', () {
    String bearerToken = '';
    String todoId = '';
    setUpAll(() => Future.sync(() => apisvc.main()));

    tearDownAll(() => apisvc.app.shutdown());

    group('should return json error message', () {
      test('when `body` is not provided when creating user', () async {
        await (await request(apisvc.app))
            .put('/api/users/create')
            .expectStatus(HttpStatus.badRequest)
            .expectHeader(HttpHeaders.contentTypeHeader,
                'application/json; charset=utf-8')
            .expectBody('{"success":false,"message":"Bad request body"}')
            .test();
      });

      test(
          'when `username`, `email` and `password` are not provided when creating user',
          () async {
        await (await request(apisvc.app))
            .put('/api/users/create', body: {})
            .expectStatus(HttpStatus.badRequest)
            .expectHeader(HttpHeaders.contentTypeHeader,
                'application/json; charset=utf-8')
            .expectBody('{"success":false,"message":"Bad request body"}')
            .test();
      });
    });

    test('should return json error when email is already in use', () async {
      await (await request(apisvc.app))
          .put('/api/users/create', body: {
            "username": "Samuel Twumasi",
            "email": "samuel@gmail.com",
            "password": "123456"
          })
          .expectStatus(HttpStatus.internalServerError)
          .expectHeader(
              HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8')
          .expectBody(
              '{"success":false,"message":"${AuthClientErrorCode.emailAlreadyExists.message}"}')
          .test();
    });

    test('should create a user with new email', () async {
      await (await request(apisvc.app))
          .put('/api/users/create', body: {
            "username": "Samuel Twumasi",
            "email": "samueltuga${Random().nextInt(100)}@gmail.com",
            "password": "123456"
          })
          .expectStatus(HttpStatus.success)
          .expectHeader(
            HttpHeaders.contentTypeHeader,
            'application/json; charset=utf-8',
          )
          .expectBodyCustom((body) {
            // Parse the JSON string
            Map<String, dynamic> jsonData = json.decode(body);
            bearerToken = jsonData['data']['token'];
            return jsonData['message'];
          }, "User created successfully")
          .test();
    });

    group('should return json error message', () {
      test('when `token` is not set in headers', () async {
        await (await request(apisvc.app))
            .put('/api/todo/add')
            .expectStatus(HttpStatus.accessDenied)
            .expectHeader(HttpHeaders.contentTypeHeader,
                'application/json; charset=utf-8')
            .expectBodyCustom((result) {
          return json.decode(result)['message'];
        }, "No authorization token was found").test();
      });
      test('when `body` is not provided when adding todo', () async {
        await (await request(apisvc.app))
            .put('/api/todo/add',
                headers: {"Authorization": "Bearer $bearerToken"})
            .expectStatus(HttpStatus.badRequest)
            .expectHeader(HttpHeaders.contentTypeHeader,
                'application/json; charset=utf-8')
            .expectBody('{"success":false,"message":"Bad request body"}')
            .test();
      });

      test('when `content` is not provided when adding todo', () async {
        await (await request(apisvc.app))
            .put(
              '/api/todo/add',
              headers: {"Authorization": "Bearer $bearerToken"},
              body: {},
            )
            .expectStatus(HttpStatus.badRequest)
            .expectHeader(HttpHeaders.contentTypeHeader,
                'application/json; charset=utf-8')
            .expectBody('{"success":false,"message":"Bad request body"}')
            .test();
      });
    });

    test('should create a todo', () async {
      await (await request(apisvc.app))
          .put(
            '/api/todo/add',
            body: {"content": "This is todo 1"},
            headers: {"Authorization": "Bearer $bearerToken"},
          )
          .expectStatus(HttpStatus.success)
          .expectHeader(
            HttpHeaders.contentTypeHeader,
            'application/json; charset=utf-8',
          )
          .expectBodyCustom((body) {
            Map<String, dynamic> jsonData = json.decode(body);
            final todo = Todo.fromJson(jsonData['data']);
            todoId = todo.id;
            return jsonData['message'];
          }, 'Todo addedd successfully')
          .test();
    });

    test('should update a todo', () async {
      await (await request(apisvc.app))
          .patch(
            '/api/todo/update/$todoId',
            body: {"content": "This is todo updated"},
            headers: {"Authorization": "Bearer $bearerToken"},
          )
          .expectStatus(HttpStatus.success)
          .expectHeader(
            HttpHeaders.contentTypeHeader,
            'application/json; charset=utf-8',
          )
          .expectBodyCustom((body) {
            Map<String, dynamic> jsonData = json.decode(body);
            return jsonData['message'];
          }, 'Todo updated successfully')
          .test();
    });

    test('should retrieve a single todo', () async {
      await (await request(apisvc.app))
          .get(
            '/api/todo/retrieve/$todoId',
            headers: {"Authorization": "Bearer $bearerToken"},
          )
          .expectStatus(HttpStatus.success)
          .expectHeader(
            HttpHeaders.contentTypeHeader,
            'application/json; charset=utf-8',
          )
          .expectBodyCustom((body) {
            Map<String, dynamic> jsonData = json.decode(body);
            return jsonData['message'];
          }, 'Success')
          .test();
    });

    test('should delete a todo', () async {
      await (await request(apisvc.app))
          .delete(
            '/api/todo/delete/$todoId',
            headers: {"Authorization": "Bearer $bearerToken"},
          )
          .expectStatus(HttpStatus.success)
          .expectHeader(
            HttpHeaders.contentTypeHeader,
            'application/json; charset=utf-8',
          )
          .expectBodyCustom((body) {
            Map<String, dynamic> jsonData = json.decode(body);
            return jsonData;
          }, {"success": true, "message": "Todo deleted successfully"})
          .test();
    });

    test('should return a list of todos', () async {
      await (await request(apisvc.app))
          .get(
            '/api/todo/list',
            headers: {"Authorization": "Bearer $bearerToken"},
          )
          .expectStatus(HttpStatus.success)
          .expectHeader(
            HttpHeaders.contentTypeHeader,
            'application/json; charset=utf-8',
          )
          .expectBodyCustom((body) {
            Map<String, dynamic> jsonData = json.decode(body);
            return jsonData['message'];
          }, 'Success')
          .test();
    });
  });
}
