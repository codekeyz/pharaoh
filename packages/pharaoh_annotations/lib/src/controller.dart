import 'dart:collection';

import 'package:pharaoh/pharaoh.dart';
import 'package:meta/meta_meta.dart';

import 'methods.dart';

class Middleware {
  final HandlerFunc handler;
  const Middleware(this.handler);
}

@Target({TargetKind.classType})
class Controller {
  final String? name;
  final String path;
  const Controller({this.path = '/', this.name});
}

abstract class BaseController {
  final List<HandlerFunc> _middlewares = [];

  List<HandlerFunc> get middlewares => UnmodifiableListView(_middlewares);

  useMiddleware(HandlerFunc func) {
    _middlewares.add(func);
  }
}

final session = cookieParser();

@Controller()
class UserController extends BaseController {
  @override
  List<HandlerFunc> get middlewares => [logRequests];

  @Get()
  Response getUsers(Request request, Response response) {
    return response.ok('Hello WOrld 🚀');
  }

  @Post()
  Response createUser(Request request, Response response) {
    return response.ok('Hello Me 🚀');
  }
}
