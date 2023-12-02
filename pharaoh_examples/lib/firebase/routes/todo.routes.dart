import 'package:pharaoh_jwt_auth/pharaoh_jwt_auth.dart';

import '../controllers/todo.controllers.dart';
import '../index.dart';
import '../utils.dart';

final todoRoutes = app.router()
  ..use(jwtAuth(secret: () => SecretKey(envVariables['JWT_SECRET'])))
  ..put('/add', TodoController.addTodo)
  ..patch('/update/:id', TodoController.updateTodo);
