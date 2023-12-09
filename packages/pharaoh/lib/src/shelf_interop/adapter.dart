import 'dart:async';

import '../http/request_impl.dart';
import '../http/response_impl.dart';
import '../router/router_handler.dart';
import '../utils/exceptions.dart';
import 'shelf.dart' as shelf;

typedef ShelfMiddlewareType2 = FutureOr<shelf.Response> Function(shelf.Request);

/// Use this hook to transform any shelf
/// middleware into a [Middleware] that Pharaoh
/// can use.
///
/// This will also throw an Exception if you use a Middleware
/// that has a [Type] signature different from either [shelf.Middleware]
/// or [ShelfMiddlewareType2] tho in most cases, it should work.
Middleware useShelfMiddleware(dynamic middleware) {
  if (middleware is shelf.Middleware) {
    return (req, res, next) async {
      final shelfResponse =
          await middleware((req) => shelf.Response.ok(req.read()))(_toShelfRequest(req));
      res = _fromShelfResponse((req: req, res: res), shelfResponse);

      next(res);
    };
  }

  if (middleware is ShelfMiddlewareType2) {
    return (req, res, next) async {
      final shelfResponse = await middleware(_toShelfRequest(req));
      res = _fromShelfResponse((req: req, res: res), shelfResponse);

      /// TODO(codekeyz) find out how to end or let the request continue
      /// based off the shelf response
      next(res.end());
    };
  }

  throw PharaohException.value('Unknown Shelf Middleware Type', middleware);
}

shelf.Request _toShelfRequest($Request req) {
  final httpReq = req.req;

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

$Response _fromShelfResponse(ReqRes reqRes, shelf.Response response) {
  Map<String, dynamic> headers = reqRes.res.headers;
  response.headers.forEach((key, value) => headers[key] = value);
  return $Response(
    reqRes.req.req,
    body: shelf.Body(response.read()),
    headers: headers,
    statusCode: response.statusCode,
    encoding: response.encoding,
    ended: false,
  );
}
