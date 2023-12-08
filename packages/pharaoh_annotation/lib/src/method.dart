import 'package:meta/meta_meta.dart';
import 'package:pharaoh/pharaoh.dart';

@Target({TargetKind.method})
class RouteMapping {
  final List<HTTPMethod> methods;
  final String path;

  const RouteMapping(this.methods, this.path);
}

class Get extends RouteMapping {
  const Get({
    String path = '/',
  }) : super(const [HTTPMethod.GET], path);
}

class Post extends RouteMapping {
  const Post({
    String path = '/',
  }) : super(const [HTTPMethod.POST], path);
}

class Put extends RouteMapping {
  const Put({
    String path = '/',
  }) : super(const [HTTPMethod.PUT], path);
}

class Patch extends RouteMapping {
  const Patch({
    String path = '/',
  }) : super(const [HTTPMethod.PATCH], path);
}

class Delete extends RouteMapping {
  const Delete({
    String path = '/',
  }) : super(const [HTTPMethod.DELETE], path);
}

class Trace extends RouteMapping {
  const Trace({
    String path = '/',
  }) : super(const [HTTPMethod.TRACE], path);
}

class Options extends RouteMapping {
  const Options({
    String path = '/',
  }) : super(const [HTTPMethod.OPTIONS], path);
}

class AllMethods extends RouteMapping {
  const AllMethods({
    String path = '/*',
  }) : super(const [HTTPMethod.ALL], path);
}
