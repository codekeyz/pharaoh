import 'package:pharaoh/pharaoh.dart';
import 'package:pharaoh_annotation/src/reflector.dart';

import 'controller.dart';

class PharaohAppFactory {
  final Pharaoh _app;
  final List<BaseController> controllers;

  PharaohAppFactory({
    Pharaoh? custom,
    this.controllers = const [],
  }) : _app = custom ?? Pharaoh();

  Future<Pharaoh> build() async {
    for (final ctrl in controllers) {
      setupControllers(_app, ctrl);
    }

    return _app;
  }
}
