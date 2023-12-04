import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dart_firebase_admin/auth.dart';
import 'package:pharaoh_examples/firebase/domain/models/todo.model.dart';
import 'package:pharaoh_examples/firebase/domain/models/user.model.dart';
import 'package:pharaoh_examples/firebase/handlers/handler.utils.dart';
import 'package:pharaoh_examples/firebase/index.dart' as apisvc;
import 'package:http/http.dart' as http;
import 'package:pharaoh_jwt_auth/pharaoh_jwt_auth.dart';
import 'package:test/test.dart';

void main() {
  group('firebase_example', () {
    String bearerToken = '';
    String todoId = '';
    setUpAll(() => Future.sync(() => apisvc.main()));

    tearDownAll(() => apisvc.app.shutdown());

    group('should return json error message', () {
      test('when `body` is not provided when creating user', () async {
        final serverUrl = apisvc.app.uri.toString();
        final path = Uri.parse('$serverUrl/api/users/create');

        final result = await http.put(path);

        expect(result.statusCode, HttpStatus.badRequest);
        expect(
          result.headers[HttpHeaders.contentTypeHeader],
          'application/json; charset=utf-8',
        );
        expect(result.body, '{"success":false,"message":"Bad request body"}');
      });

      test(
          'when `username`, `email` and `password` are not provided when creating user',
          () async {
        final serverUrl = apisvc.app.uri.toString();
        final path = Uri.parse('$serverUrl/api/users/create');

        final result = await http.put(path, body: {});
        expect(result.statusCode, HttpStatus.badRequest);
        expect(
          result.headers[HttpHeaders.contentTypeHeader],
          'application/json; charset=utf-8',
        );
        expect(result.body, '{"success":false,"message":"Bad request body"}');
      });
    });

    test('should return json error when email is already in use', () async {
      final serverUrl = apisvc.app.uri.toString();
      final path = Uri.parse('$serverUrl/api/users/create');

      final result = await http.put(path, body: {
        "username": "Samuel Twumasi",
        "email": "samuel@gmail.com",
        "password": "123456"
      });
      expect(
        result.headers[HttpHeaders.contentTypeHeader],
        'application/json; charset=utf-8',
      );
      expect(result.statusCode, HttpStatus.internalServerError);
      expect(result.body,
          '{"success":false,"message":"${AuthClientErrorCode.emailAlreadyExists.message}"}');
    });

    test('should create a user with new email', () async {
      final serverUrl = apisvc.app.uri.toString();
      final path = Uri.parse('$serverUrl/api/users/create');

      final result = await http.put(path, body: {
        "username": "Samuel Twumasi",
        "email": "samueltuga${Random().nextInt(100)}@gmail.com",
        "password": "123456"
      });

      // Parse the JSON string
      Map<String, dynamic> jsonData = json.decode(result.body);

      bearerToken = jsonData['data']['token'];

      final token = JWT.tryDecode(jsonData['data']['token']);
      final user = User.fromJson(jsonData['data']['user']);

      expect(
        result.headers[HttpHeaders.contentTypeHeader],
        'application/json; charset=utf-8',
      );
      expect(result.statusCode, HttpStatus.success);
      expect(jsonData['success'], true);
      expect(jsonData['message'], "User created successfully");
      expect(user, isA<User>());
      expect(user.uid, isNotEmpty);
      expect(user.email, isNotEmpty);
      expect(user.displayName, isNotEmpty);
      expect(token, isA<JWT>());
      expect(token?.payload, isNotNull);
      expect(token?.payload['userId'], user.uid);
      expect(token?.payload['email'], user.email);
    });

    group('should return json error message', () {
      test('when `token` is not set in headers', () async {
        final serverUrl = apisvc.app.uri.toString();
        final path = Uri.parse('$serverUrl/api/todo/add');

        final result = await http.put(path);

        expect(result.statusCode, HttpStatus.accessDenied);
        expect(
          result.headers[HttpHeaders.contentTypeHeader],
          'application/json; charset=utf-8',
        );
        expect(json.decode(result.body)['message'],
            "No authorization token was found");
      });
      test('when `body` is not provided when adding todo', () async {
        final serverUrl = apisvc.app.uri.toString();
        final path = Uri.parse('$serverUrl/api/todo/add');

        final result = await http
            .put(path, headers: {"Authorization": "Bearer $bearerToken"});

        expect(result.statusCode, HttpStatus.badRequest);
        expect(
          result.headers[HttpHeaders.contentTypeHeader],
          'application/json; charset=utf-8',
        );
        expect(result.body, '{"success":false,"message":"Bad request body"}');
      });

      test('when `content` is not provided when adding todo', () async {
        final serverUrl = apisvc.app.uri.toString();
        final path = Uri.parse('$serverUrl/api/todo/add');

        final result = await http.put(
          path,
          body: {},
          headers: {"Authorization": "Bearer $bearerToken"},
        );
        expect(result.statusCode, HttpStatus.badRequest);
        expect(
          result.headers[HttpHeaders.contentTypeHeader],
          'application/json; charset=utf-8',
        );
        expect(result.body, '{"success":false,"message":"Bad request body"}');
      });
    });

    test('should create a todo', () async {
      final serverUrl = apisvc.app.uri.toString();
      final path = Uri.parse('$serverUrl/api/todo/add');

      final result = await http.put(
        path,
        body: {"content": "This is todo 1"},
        headers: {"Authorization": "Bearer $bearerToken"},
      );
      Map<String, dynamic> jsonData = json.decode(result.body);

      final todo = Todo.fromJson(jsonData['data']);
      todoId = todo.id;

      expect(result.statusCode, HttpStatus.success);
      expect(
        result.headers[HttpHeaders.contentTypeHeader],
        'application/json; charset=utf-8',
      );
      expect(todo, isA<Todo>());
      expect(todo.id, isNotEmpty);
      expect(jsonData['message'], 'Todo addedd successfully');
    });

    test('should update a todo', () async {
      final serverUrl = apisvc.app.uri.toString();
      final path = Uri.parse('$serverUrl/api/todo/update/$todoId');

      final result = await http.patch(
        path,
        body: {"content": "This is todo updated"},
        headers: {"Authorization": "Bearer $bearerToken"},
      );

      Map<String, dynamic> jsonData = json.decode(result.body);

      final todo = Todo.fromJson(jsonData['data']);

      expect(result.statusCode, HttpStatus.success);
      expect(
        result.headers[HttpHeaders.contentTypeHeader],
        'application/json; charset=utf-8',
      );
      expect(todo, isA<Todo>());
      expect(todo.id, isNotEmpty);
      expect(jsonData['message'], 'Todo updated successfully');
    });

    test('should retrieve a single todo', () async {
      final serverUrl = apisvc.app.uri.toString();
      final path = Uri.parse('$serverUrl/api/todo/retrieve/$todoId');

      final result = await http.get(
        path,
        headers: {"Authorization": "Bearer $bearerToken"},
      );

      Map<String, dynamic> jsonData = json.decode(result.body);

      final todo = Todo.fromJson(jsonData['data']);

      expect(result.statusCode, HttpStatus.success);
      expect(
        result.headers[HttpHeaders.contentTypeHeader],
        'application/json; charset=utf-8',
      );
      expect(todo, isA<Todo>());
      expect(todo.id, isNotEmpty);
      expect(jsonData['message'], 'Success');
    });

    test('should delete a todo', () async {
      final serverUrl = apisvc.app.uri.toString();
      final path = Uri.parse('$serverUrl/api/todo/delete/$todoId');

      final result = await http.delete(
        path,
        headers: {"Authorization": "Bearer $bearerToken"},
      );

      Map<String, dynamic> jsonData = json.decode(result.body);

      expect(result.statusCode, HttpStatus.success);
      expect(
        result.headers[HttpHeaders.contentTypeHeader],
        'application/json; charset=utf-8',
      );
      expect(
        jsonData,
        {"success": true, "message": "Todo deleted successfully"},
      );
    });

    test('should return a list of todos', () async {
      final serverUrl = apisvc.app.uri.toString();
      final path = Uri.parse('$serverUrl/api/todo/list');

      final result = await http.get(
        path,
        headers: {"Authorization": "Bearer $bearerToken"},
      );

      Map<String, dynamic> jsonData = json.decode(result.body);

      expect(result.statusCode, HttpStatus.success);
      expect(
        result.headers[HttpHeaders.contentTypeHeader],
        'application/json; charset=utf-8',
      );
      expect(jsonData['success'], true);
      expect(jsonData['message'], 'Success');
    });
  });
}
