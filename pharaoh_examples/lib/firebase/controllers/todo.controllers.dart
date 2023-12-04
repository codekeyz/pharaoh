import 'package:pharaoh/pharaoh.dart';

import '../domain/requests/createTodo.request.dart';
import '../handlers/handler.utils.dart';
import '../handlers/response.handler.dart';
import '../services/todo.service.dart';
import '../utils.dart';

class TodoController {
  TodoController._();

  static addTodo($Request req, $Response res) async {
    try {
      if (req.body is! Map) {
        throw ApiError('Bad request body', HttpStatus.badRequest);
      }

      if (!req.body.containsKey('content')) {
        throw ApiError('Bad request body', HttpStatus.badRequest);
      }

      String content = req.body['content'];

      // create a fake id but will later change it to be the document's id
      final todo = CreateTodoRequest(content, false);

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
        message: 'Todo updated successfully',
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
      int page = 1;
      int limit = 2;

      if (req.query.containsKey('page')) {
        page = int.parse(req.query['page']);
      }

      if (req.query.containsKey('limit')) {
        limit = int.parse(req.query['limit']);
      }

      final todosList = await TodoService.listTodos(
        page: page,
        limit: limit,
      );

      return ResponseHandler(res).successWithData(todosList.toJson());
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
