import 'package:meta/meta_meta.dart';
import 'package:pharaoh/pharaoh.dart';
import 'reflector/_middleware.dart';

@Target({TargetKind.classType})
class Controller {
  final String? name;
  final String path;
  const Controller({this.path = '/', this.name});
}

abstract class BaseController {
  final Set<MiddlewareDefinition> middlewares = {};

  late Pharaoh app = throw UnimplementedError('Controller not yet initialized');

  void useMdw(Middleware middleware) {
    middlewares.add(MiddlewareDefinition(middleware));
  }

  void useScopedMdw(MiddlewareDefinition definition) {
    middlewares.add(definition);
  }

  void setAppInstance(Pharaoh appInstance) {
    app = appInstance;
  }
}
