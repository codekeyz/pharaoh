part of '../router.dart';

String cleanRoute(String route) {
  final result =
      route.replaceAll(RegExp(r'/+'), '/').replaceAll(RegExp(r'/$'), '');
  return result.isEmpty ? '/' : result;
}

String symbolToString(Symbol symbol) {
  final str = symbol.toString();
  return str.substring(8, str.length - 2);
}
