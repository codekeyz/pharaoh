import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mason_logger/mason_logger.dart';

import '../pharaoh.dart';
import 'http/request.dart';
import 'http/response.dart';
import 'middleware/body_parser.dart';
import 'router/handler.dart';
import 'shelf_interop/shelf.dart' as shelf;

class $PharaohImpl implements Pharaoh {
  late final PharaohRouter _router;
  late final HttpServer _server;
  late final Logger _logger;

  $PharaohImpl()
      : _logger = Logger(),
        _router = PharaohRouter() {
    _router.use(bodyParser);
  }

  @override
  Uri get uri {
    if (_server.address.isLoopback) {
      return Uri(scheme: 'http', host: 'localhost', port: _server.port);
    }

    // IPv6 addresses in URLs need to be enclosed in square brackets to avoid
    // URL ambiguity with the ":" in the address.
    if (_server.address.type == InternetAddressType.IPv6) {
      return Uri(
        scheme: 'http',
        host: '[${_server.address.address}]',
        port: _server.port,
      );
    }

    return Uri(
      scheme: 'http',
      host: _server.address.address,
      port: _server.port,
    );
  }

  @override
  PharaohRouter router() => PharaohRouter();

  @override
  List<Route> get routes => _router.routes;

  @override
  Pharaoh delete(String path, RequestHandlerFunc handler) {
    _router.delete(path, handler);
    return this;
  }

  @override
  Pharaoh get(String path, RequestHandlerFunc handler) {
    _router.get(path, handler);
    return this;
  }

  @override
  Pharaoh post(String path, RequestHandlerFunc handler) {
    _router.post(path, handler);
    return this;
  }

  @override
  Pharaoh put(String path, RequestHandlerFunc handler) {
    _router.put(path, handler);
    return this;
  }

  @override
  Pharaoh use(HandlerFunc reqResNext, [Route? route]) {
    _router.use(reqResNext, route);
    return this;
  }

  @override
  Pharaoh group(final String path, final RouteHandler handler) {
    final route = Route.path(path);

    if (handler is PharaohRouter) {
      _router.use((req, res, next) async {
        final result = await drainRouter(handler.prefix(path), (
          req: req,
          res: res,
        ));

        if (!result.canNext) {
          next();
          return;
        }

        next(result.reqRes.res);
      }, route);
      return this;
    }

    _router.use(handler.handler, route);
    return this;
  }

  @override
  Future<Pharaoh> listen({int port = 3000}) async {
    final progress = _logger.progress('Starting server');

    try {
      _server = await HttpServer.bind('localhost', port);
      _server.listen(handleRequest);
      progress.complete('Server start on PORT: $port -> ${uri.toString()}');
    } catch (e) {
      final errMsg =
          (e as dynamic).message ?? 'An occurred while starting server';
      progress.fail(errMsg);
    }

    return this;
  }

  void handleRequest(HttpRequest httpReq) async {
    // An adapter must not add or modify the `Transfer-Encoding` parameter, but
    // the Dart SDK sets it by default. Set this before we fill in
    // [response.headers] so that the user or Shelf can explicitly override it if
    // necessary.
    httpReq.response.headers.chunkedTransferEncoding = false;
    httpReq.response.headers.clear();

    final req = Request.from(httpReq);
    final result =
        await drainRouter(_router, (req: req, res: Response.from(httpReq)));
    if (result.canNext == false) return;

    final res = result.reqRes.res;
    if (res.ended) return forward(httpReq, res);

    return forward(
        httpReq,
        res
            .type(ContentType.json)
            .notFound("No handlers registered for path: ${req.path}"));
  }

  Future<HandlerResult> drainRouter(
    PharaohRouter routerX,
    ReqRes reqRes,
  ) async {
    try {
      return await routerX.handle(reqRes);
    } catch (e) {
      final res = reqRes.res.internalServerError(e.toString());
      return (
        canNext: true,
        reqRes: (req: reqRes.req, res: res),
      );
    }
  }

  bool hasNoRequestHandlers(List<RouteHandler> handlers) =>
      !handlers.any((e) => e is RequestHandler);

  Future<void> forward(HttpRequest request, Response res_) async {
    var coding = res_.headers['transfer-encoding'];

    final statusCode = res_.statusCode;
    if (coding != null && !equalsIgnoreAsciiCase(coding, 'identity')) {
      // If the response is already in a chunked encoding, de-chunk it because
      // otherwise `dart:io` will try to add another layer of chunking.
      //
      // TODO(codekeyz): Do this more cleanly when sdk#27886 is fixed.
      final newStream = chunkedCoding.decoder.bind(res_.body!.read());
      res_ = Response.from(request)..body = shelf.Body(newStream);
      request.headers.set(HttpHeaders.transferEncodingHeader, 'chunked');
    } else if (statusCode >= 200 &&
        statusCode != 204 &&
        statusCode != 304 &&
        res_.contentLength == null &&
        res_.mimeType != 'multipart/byteranges') {
      // If the response isn't chunked yet and there's no other way to tell its
      // length, enable `dart:io`'s chunked encoding.
      request.response.headers
          .set(HttpHeaders.transferEncodingHeader, 'chunked');
    }

    // headers to write to the response
    final hders = res_.headers;

    hders.forEach((key, value) => request.response.headers.add(key, value));

    if (!hders.containsKey(_XPoweredByHeader)) {
      request.response.headers.add(_XPoweredByHeader, 'Pharaoh');
    }
    if (!hders.containsKey(HttpHeaders.dateHeader)) {
      request.response.headers
          .add(HttpHeaders.dateHeader, DateTime.now().toUtc());
    }
    if (!hders.containsKey(HttpHeaders.contentLengthHeader)) {
      final contentLength = res_.contentLength;
      if (contentLength != null) {
        request.response.headers
            .add(HttpHeaders.contentLengthHeader, contentLength);
      }
    }

    request.response.statusCode = statusCode;

    return request.response
        .addStream(res_.body!.read())
        .then((_) => request.response.close());
  }

  @override
  Future<void> shutdown() async {
    await _server.close();
  }
}

// ignore: constant_identifier_names
const _XPoweredByHeader = 'X-Powered-By';
