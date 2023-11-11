import '../request.dart';
import 'route.dart';
import 'router.dart';

class RouteGroup {
  final String prefix;
  final List<RouteHandler> handlers = [];

  RouteGroup(this.prefix);

  void add(RouteHandler handler) {
    var route = handler.route;

    if (route.route.trim().isEmpty) {
      throw Exception('Routes should being with $BASE_PATH');
    }

    if (![BASE_PATH, ANY_PATH].contains(prefix)) {
      handler.prefix(prefix);
    }

    /// TODO: do checks here to make sure there's no duplicate entry in the routes
    handlers.add(handler);
  }

  List<RouteHandler> findHandlers(Request request) => handlers.isEmpty
      ? []
      : handlers.where((e) => e.route.canHandle(request)).toList();
}
