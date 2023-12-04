import 'dart:math';

import 'package:dart_firebase_admin/firestore.dart';
import 'package:pharaoh_examples/firebase/handlers/handler.utils.dart';
import 'package:pharaoh_examples/firebase/handlers/pagination.dart';

import '../domain/models/todo.model.dart';
import '../domain/requests/createTodo.request.dart';
import '../utils.dart';
import '../locator/locator.dart';

class TodoService {
  TodoService._();

  static Future<Todo> addTodo(CreateTodoRequest request) async {
    try {
      final todoCollection = locator.store.collection('todos');

      final docRef = await todoCollection.add(request.toJson());

      final snapshot = await docRef.get();

      final result = snapshot.data();

      final todo = Todo(
        id: snapshot.id,
        content: result!['content'] as String,
        isCompleted: result['isCompleted'] as bool,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          snapshot.createTime!.seconds * 1000,
        ),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
          snapshot.updateTime!.seconds * 1000,
        ),
      );

      await docRef.set(todo.toJson());

      final finalResult = (await docRef.get()).data();

      return Todo.fromJson(finalResult!);
    } on FirebaseFirestoreAdminException catch (err) {
      throw ApiError(err.code, HttpStatus.internalServerError);
    }
  }

  static Future<Todo> updateTodo({
    required String id,
    String? content,
    bool? isCompleted,
  }) async {
    try {
      final docRef = locator.store.doc('todos/$id');

      final doc = (await docRef.get()).data();

      if (doc == null) {
        throw ApiError('Todo not found', HttpStatus.notFound);
      }

      await docRef.update({
        "content": content ?? doc['content'],
        "isCompleted": isCompleted ?? doc['isCompleted'],
        "updatedAt": DateTime.now().toUtc().toIso8601String(),
      });

      final result = (await docRef.get()).data();

      return Todo.fromJson(result!);
    } on FirebaseFirestoreAdminException catch (err) {
      throw ApiError(err.code, HttpStatus.internalServerError);
    } catch (err) {
      rethrow;
    }
  }

  static Future<Todo> getSingleTodo(id) async {
    try {
      final docRef = locator.store.doc('todos/$id');

      final doc = (await docRef.get()).data();

      if (doc == null) {
        throw ApiError('Todo not found', HttpStatus.notFound);
      }

      return Todo.fromJson(doc);
    } on FirebaseFirestoreAdminException catch (err) {
      throw ApiError(err.code, 500);
    } catch (err) {
      rethrow;
    }
  }

  static Future<Pagination> listTodos(
      {required int page, required int limit}) async {
    try {
      final collectionRef = locator.store.collection('todos');

      final totalCount = (await collectionRef.listDocuments()).length;

      final todosSnapshot = await collectionRef
          .limit(limit)
          .offset((page - 1) * limit)
          .orderBy('createdAt', descending: false)
          .get();

      List<Todo> todos = [];

      for (var todo in todosSnapshot.docs) {
        todos.add(Todo.fromJson(todo.data()));
      }

      return Pagination(
        data: List.from(todos.map((e) => e.toJson())),
        count: totalCount,
        page: page,
      );
    } on FirebaseFirestoreAdminException catch (err) {
      throw ApiError(err.code, HttpStatus.internalServerError);
    }
  }

  static Future<void> deleteTodo(String id) async {
    try {
      final docRef = locator.store.doc('todos/$id');

      await docRef.delete();
    } on FirebaseFirestoreAdminException catch (err) {
      throw ApiError(err.code, HttpStatus.internalServerError);
    }
  }
}
