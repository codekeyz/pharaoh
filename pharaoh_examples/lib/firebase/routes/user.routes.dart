import '../controllers/user.controllers.dart';
import '../../route_groups/index.dart';

final userRoutes = app.router()..put('/create', UserController.createUser);
