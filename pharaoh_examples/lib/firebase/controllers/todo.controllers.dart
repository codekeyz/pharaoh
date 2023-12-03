import 'package:pharaoh/pharaoh.dart';

import '../handlers/handler.utils.dart';
import '../handlers/response.handler.dart';
import '../domain/models/todo.model.dart';
import '../services/todo.service.dart';
import '../utils.dart';

class TodoController {
  TodoController._();

  static addTodo($Request req, $Response res) async {
    try {
      if (req.body is! Map) {
        throw ApiError('Invalid request body', HttpStatus.badRequest);
      }

      String content = req.body['content'];

      // create a fake id but will later change it to be the document's id
      final todo = Todo(id: DateTime.now().toIso8601String(), content: content);

      final savedTodo = await TodoService.addTodo(todo);

      return ResponseHandler(res).successWithData(
        savedTodo.toJson(),
        message: 'Todo addedd successfully',
      );
    } on ApiError catch (err) {
      return ResponseHandler(res).error(err);
    }
  }

  static updateTodo($Request req, $Response res) async {
    try {
      final id = req.params['id'];

      String? content;

      if ((req.body as Map).containsKey('content')) {
        content = req.body['content'];
      }
      bool? isCompleted;

      if ((req.body as Map).containsKey('isCompleted')) {
        isCompleted = req.body['isCompleted'];
      }

      final updatedTodo = await TodoService.updateTodo(
        id: id,
        content: content,
        isCompleted: isCompleted,
      );

      return ResponseHandler(res).successWithData(
        updatedTodo.toJson(),
        message: 'Todo has been updated successfully',
      );
    } on ApiError catch (err) {
      return ResponseHandler(res).error(err);
    }
  }

  static getSingleTodo($Request req, $Response res) async {
    try {
      final id = req.params['id'];

      final savedTodo = await TodoService.getSingleTodo(id);

      return ResponseHandler(res).successWithData(savedTodo.toJson());
    } on ApiError catch (err) {
      return ResponseHandler(res).error(err);
    }
  }

  static listTodos($Request req, $Response res) async {
    try {
      final todosList = await TodoService.listTodos();

      return ResponseHandler(res).successWithData(
        List.from(todosList.map((todo) => todo.toJson())),
      );
    } on ApiError catch (err) {
      return ResponseHandler(res).error(err);
    }
  }

  static deleteTodo($Request req, $Response res) async {
    try {
      final id = req.params['id'];
      await TodoService.deleteTodo(id);

      return ResponseHandler(res).success('Todo deleted successfully');
    } on ApiError catch (err) {
      return ResponseHandler(res).error(err);
    }
  }
}
