import 'dart:async';

import 'package:jinja/jinja.dart';

abstract class ViewEngine {
  String get name;

  FutureOr<String> render(String template, Map<String, dynamic> data);
}

class JinjaViewEngine implements ViewEngine {
  final String fileExt;
  final List<String> filePaths;
  late final Environment _environment;

  JinjaViewEngine(
    this._environment, {
    this.filePaths = const [],
    this.fileExt = 'html',
  });

  @override
  FutureOr<String> render(
    String name,
    Map<String, dynamic> data,
  ) =>
      _environment.getTemplate('$name.$fileExt').render(data);

  @override
  String get name => 'Jinja';
}
