import '../http/request.dart';
import 'router_handler.dart';

abstract class RouterContract<T> {
  T get(String path, RequestHandlerFunc hdler);

  T post(String path, RequestHandlerFunc hdler);

  T put(String path, RequestHandlerFunc hdler);

  T delete(String path, RequestHandlerFunc hdler);

  T head(String path, RequestHandlerFunc hdler);

  T patch(String path, RequestHandlerFunc hdler);

  T options(String path, RequestHandlerFunc hdler);

  T trace(String path, RequestHandlerFunc hdler);

  T use(HandlerFunc mdw);

  T useOnPath(
    String path,
    HandlerFunc func, {
    HTTPMethod method = HTTPMethod.ALL,
  });
}
