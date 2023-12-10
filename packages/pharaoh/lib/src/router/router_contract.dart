import 'package:spanner/spanner.dart';

import 'router_handler.dart';

abstract class RouterContract {
  void get(String path, RequestHandler hdler);

  void post(String path, RequestHandler hdler);

  void put(String path, RequestHandler hdler);

  void delete(String path, RequestHandler hdler);

  void head(String path, RequestHandler hdler);

  void patch(String path, RequestHandler hdler);

  void options(String path, RequestHandler hdler);

  void trace(String path, RequestHandler hdler);

  void use(Middleware middleware);

  void on(String path, Middleware hdler, {HTTPMethod method = HTTPMethod.ALL});
}
