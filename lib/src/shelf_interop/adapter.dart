import '../http/request.dart';
import '../http/response.dart';
import 'shelf.dart' as shelf;

extension ShelfResponseMixin on shelf.Response {
  void copyTo(Response res) {
    res
      ..status(statusCode)
      ..body = shelf.Body(read())
      ..updateHeaders((headers) => headers
        ..clear()
        ..addAll(headers));
  }
}

shelf.Request toShelfRequest($Request req) {
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
