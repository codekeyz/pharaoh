import '../http/request.dart';
import '../http/response.dart';
import '../router/handler.dart';
import 'shelf.dart' as shelf;

extension _ShelfResponseMixin on shelf.Response {
  void copyTo(Response res) {
    res
      ..status(statusCode)
      ..body = shelf.Body(read())
      ..updateHeaders((hders) => hders
        ..clear()
        ..addAll(headers));
  }
}

shelf.Request _toShelfRequest($Request req) {
  final httpReq = (req as Request).req;

  var headers = <String, List<String>>{};
  httpReq.headers.forEach((k, v) {
    headers[k] = v;
  });

  return shelf.Request(
    httpReq.method,
    httpReq.requestedUri,
    protocolVersion: httpReq.protocolVersion,
    headers: headers,
    body: httpReq,
    context: {'shelf.io.connection_info': httpReq.connectionInfo!},
  );
}

MiddlewareFunc useShelfMiddleware(shelf.Middleware middleware) {
  return (Request req, Response res, Function next) async {
    final shelfResponse = await middleware(
        (req) => shelf.Response.ok(req.read()))(_toShelfRequest(req));
    shelfResponse.copyTo(res);

    next();
  };
}
