import 'package:pharaoh/pharaoh.dart';

class MiddlewareDefinition {
  final Middleware mdw;
  final Set<Symbol> methods;

  const MiddlewareDefinition(
    this.mdw, {
    this.methods = const {},
  });
}
