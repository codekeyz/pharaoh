import 'package:pharaoh/pharaoh.dart';

import 'reflector/_middleware.dart';

extension MiddlewareScope on Middleware {
  MiddlewareDefinition only(dynamic symbolOrSymbols) {
    final Set<Symbol> symbols = switch (symbolOrSymbols.runtimeType) {
      const (List<Symbol>) => {...(symbolOrSymbols as List<Symbol>)},
      const (Symbol) => {symbolOrSymbols},
      _ => throw ArgumentError.value(
          symbolOrSymbols,
          null,
          'Middleware `.only` can only accept `Symbol` or `Iterable<Symbol>`',
        )
    };
    return MiddlewareDefinition(this, methods: symbols);
  }
}
