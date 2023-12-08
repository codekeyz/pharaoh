import 'package:meta/meta_meta.dart';
import 'package:pharaoh/pharaoh.dart';

@Target({TargetKind.method})
abstract class RouteDefinition {
  final HTTPMethod method;
  final String path;

  const RouteDefinition(this.method, this.path);
}

class Get extends RouteDefinition {
  const Get({String path = '/'}) : super(HTTPMethod.GET, path);
}

class Post extends RouteDefinition {
  const Post({String path = '/'}) : super(HTTPMethod.POST, path);
}

class Put extends RouteDefinition {
  const Put({String path = '/'}) : super(HTTPMethod.PUT, path);
}

class Patch extends RouteDefinition {
  const Patch({String path = '/'}) : super(HTTPMethod.PATCH, path);
}

class Delete extends RouteDefinition {
  const Delete({String path = '/'}) : super(HTTPMethod.DELETE, path);
}

class Trace extends RouteDefinition {
  const Trace({String path = '/'}) : super(HTTPMethod.TRACE, path);
}

class Options extends RouteDefinition {
  const Options({String path = '/'}) : super(HTTPMethod.OPTIONS, path);
}
