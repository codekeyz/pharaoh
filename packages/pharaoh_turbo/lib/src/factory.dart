import 'package:pharaoh/pharaoh.dart';
import 'controller.dart';
import 'reflector/reflector.dart';

class PharaohTurbo {
  final Pharaoh _app;
  final List<BaseController> controllers;

  PharaohTurbo({
    Pharaoh? custom,
    this.controllers = const [],
  }) : _app = custom ?? Pharaoh();

  Pharaoh create() {
    for (final ctrl in controllers) {
      useController(_app, ctrl);
    }

    return _app;
  }
}
