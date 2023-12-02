import 'package:dart_firebase_admin/firestore.dart';
import 'package:pharaoh/pharaoh.dart';
import 'package:pharaoh_examples/firebase/locator/locator.dart';
import 'package:pharaoh_examples/firebase/models/todo.model.dart';
import 'package:pharaoh_examples/firebase/utils.dart';

class TodoController {
  TodoController._();

  static addTodo($Request req, $Response res) async {
    try {
      if (req.body is! Map) {
        throw ApiError('Invalid request body', 400);
      }

      String content = req.body['content'];

      final todo = Todo(content: content);

      final todoCollection = locator.store.collection('todos');

      final docRef = await todoCollection.add(todo.toJson());

      todo.id = docRef.id;

      await docRef.set(todo.toJson());

      final result = (await docRef.get()).data();

      return res.status(201).json({
        'success': true,
        "data": result,
      });
    } on FirebaseFirestoreAdminException catch (err) {
      return res.status(500).json({
        "success": false,
        "message": err.message,
      });
    } catch (err) {
      if (err is ApiError) {
        return res.status(err.statusCode).json({
          "success": false,
          "message": err.toString(),
        });
      }
      return res.status(400).makeError(message: err.toString());
    }
  }

  static updateTodo($Request req, $Response res) async {
    try {
      final id = req.params['id'];

      String? content;

      if ((req.body as Map).containsKey('conteent')) {
        content = req.body['content'];
      }
      bool? isCompleted;

      if ((req.body as Map).containsKey('isCompleted')) {
        content = req.body['isCompleted'];
      }

      final docRef = locator.store.doc('todos/$id');

      print(docRef);

      final doc = (await docRef.get()).data();

      await docRef.update({
        "content": content ?? doc!['content'],
        "isCompleted": isCompleted ?? doc!['isCompleted'],
      });

      final result = (await docRef.get()).data();

      return res.status(200).json({
        'success': true,
        'message': 'Todo updated successfully',
        "data": result,
      });
    } on FirebaseFirestoreAdminException catch (err) {
      return res.status(500).json({
        "success": false,
        "message": err.message,
      });
    } catch (err) {
      if (err is ApiError) {
        return res.status(err.statusCode).json({
          "success": false,
          "message": err.toString(),
        });
      }
      return res.status(400).makeError(message: err.toString());
    }
  }
}
