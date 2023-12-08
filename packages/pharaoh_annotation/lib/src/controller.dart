import 'dart:collection';
import 'package:pharaoh/pharaoh.dart';
import 'package:meta/meta_meta.dart';
import 'package:pharaoh_annotation/src/method.dart';

class Middleware {
  final RouteMapping route;
  final HandlerFunc handler;
  const Middleware(this.handler, {this.route = const AllMethods()});
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
