import '../http/request.dart';
import 'router_handler.dart';

abstract class RouterContract {
  void get(String path, RequestHandlerFunc hdler);

  void post(String path, RequestHandlerFunc hdler);

  void put(String path, RequestHandlerFunc hdler);

  void delete(String path, RequestHandlerFunc hdler);

  void head(String path, RequestHandlerFunc hdler);

  void patch(String path, RequestHandlerFunc hdler);

  void options(String path, RequestHandlerFunc hdler);

  void trace(String path, RequestHandlerFunc hdler);

  void use(HandlerFunc middleware);

  void on(String path, HandlerFunc hdler, {HTTPMethod method = HTTPMethod.ALL});
}
