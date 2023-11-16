import 'dart:async';

import '../http/request.dart';
import '../http/response.dart';
import '../router/handler.dart';
import '../utils/exceptions.dart';
import 'shelf.dart' as shelf;

typedef ShelfMiddlewareType2 = FutureOr<shelf.Response> Function(shelf.Request);

/// Use this hook to transform any shelf
/// middleware into a [HandlerFunc] that Pharaoh
/// can use.
///
/// This will also throw an Exception if you use a Middleware
/// that has a [Type] signature different from either [shelf.Middleware]
/// or [ShelfMiddlewareType2] tho in most cases, it should work.
HandlerFunc useShelfMiddleware(dynamic middleware) {
  if (middleware is shelf.Middleware) {
    return (req, res, next) async {
      final shelfResponse = await middleware(
          (req) => shelf.Response.ok(req.read()))(_toShelfRequest(req));

      res = _fromShelfResponse(req, shelfResponse);

      next(res);
    };
  }

  if (middleware is ShelfMiddlewareType2) {
    return (req, res, next) async {
      final shelfResponse = await middleware(_toShelfRequest(req));
      res = _fromShelfResponse(req, shelfResponse);

      next(res);
    };
  }

  throw PharaohException.value('Unknown Shelf Middleware Type', middleware);
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

Response _fromShelfResponse(Request req, shelf.Response response) {
  return Response.from(req.req, body: shelf.Body(response.read()))
      .status(response.statusCode)
      .updateHeaders(
          (hdrs) => response.headers.forEach((key, value) => hdrs[key] = value))
      .end();
}
