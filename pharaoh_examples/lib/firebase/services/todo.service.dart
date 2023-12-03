import 'package:dart_firebase_admin/firestore.dart';
import 'package:pharaoh_examples/firebase/handlers/handler.utils.dart';

import '../domain/models/todo.model.dart';
import '../utils.dart';
import '../locator/locator.dart';

class TodoService {
  TodoService._();

  static Future<Todo> addTodo(Todo todo) async {
    try {
      final todoCollection = locator.store.collection('todos');

      final docRef = await todoCollection.add(todo.toJson());

      // change the id to the document id
      todo.id = docRef.id;

      await docRef.set(todo.toJson());

      final result = (await docRef.get()).data();

      return Todo.fromJson(result!);
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

  static Future<List<Todo>> listTodos() async {
    try {
      final collectionRef = locator.store.collection('todos');

      final todosSnapshot = await collectionRef.get();

      List<Todo> todos = [];

      for (var todo in todosSnapshot.docs) {
        todos.add(Todo.fromJson(todo.data()));
      }

      return todos;
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
