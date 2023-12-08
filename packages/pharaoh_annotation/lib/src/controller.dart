import 'dart:collection';
import 'package:pharaoh/pharaoh.dart';
import 'package:meta/meta_meta.dart';

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
