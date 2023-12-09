// ignore_for_file: camel_case_types

import 'package:meta/meta_meta.dart';
import 'package:pharaoh/pharaoh.dart';

@Target({TargetKind.method})
class routeMapping {
  final List<HTTPMethod> methods;
  final String path;

  const routeMapping(this.methods, this.path);
}

class Get extends routeMapping {
  const Get({
    String path = '/',
  }) : super(const [HTTPMethod.GET], path);
}

class Post extends routeMapping {
  const Post({
    String path = '/',
  }) : super(const [HTTPMethod.POST], path);
}

class Put extends routeMapping {
  const Put({
    String path = '/',
  }) : super(const [HTTPMethod.PUT], path);
}

class Patch extends routeMapping {
  const Patch({
    String path = '/',
  }) : super(const [HTTPMethod.PATCH], path);
}

class Delete extends routeMapping {
  const Delete({
    String path = '/',
  }) : super(const [HTTPMethod.DELETE], path);
}

class Trace extends routeMapping {
  const Trace({
    String path = '/',
  }) : super(const [HTTPMethod.TRACE], path);
}

class Options extends routeMapping {
  const Options({
    String path = '/',
  }) : super(const [HTTPMethod.OPTIONS], path);
}
