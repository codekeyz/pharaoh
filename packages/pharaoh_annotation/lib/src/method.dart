// ignore_for_file: camel_case_types

import 'package:meta/meta_meta.dart';
import 'package:pharaoh/pharaoh.dart';

@Target({TargetKind.method})
class routeMapping {
  final List<HTTPMethod> methods;
  final String path;

  const routeMapping(this.methods, this.path);
}

class getMapping extends routeMapping {
  const getMapping({
    String path = '/',
  }) : super(const [HTTPMethod.GET], path);
}

class postMapping extends routeMapping {
  const postMapping({
    String path = '/',
  }) : super(const [HTTPMethod.POST], path);
}

class putMapping extends routeMapping {
  const putMapping({
    String path = '/',
  }) : super(const [HTTPMethod.PUT], path);
}

class patchMapping extends routeMapping {
  const patchMapping({
    String path = '/',
  }) : super(const [HTTPMethod.PATCH], path);
}

class deleteMapping extends routeMapping {
  const deleteMapping({
    String path = '/',
  }) : super(const [HTTPMethod.DELETE], path);
}

class traceMapping extends routeMapping {
  const traceMapping({
    String path = '/',
  }) : super(const [HTTPMethod.TRACE], path);
}

class optionsMapping extends routeMapping {
  const optionsMapping({
    String path = '/',
  }) : super(const [HTTPMethod.OPTIONS], path);
}
