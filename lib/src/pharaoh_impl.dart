import 'dart:io';

import 'package:mason_logger/mason_logger.dart';

import '../pharaoh.dart';
import 'http/request.dart';
import 'http/response.dart';
import 'middleware/body_parser.dart';
import 'router/handler.dart';
import 'utils/exceptions.dart';

class $PharaohImpl implements Pharaoh {
  late final PharoahRouter _router;
  late final HttpServer _server;
  late final Logger _logger;

  $PharaohImpl()
      : _logger = Logger(),
        _router = PharoahRouter() {
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
  PharoahRouter router() => PharoahRouter();

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

    if (handler is PharoahRouter) {
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
    if (res.ended) {
      return forward(httpReq.response, res);
    }

    return forward(
      httpReq.response,
      res.type(ContentType.json).notFound(),
    );
  }

  Future<HandlerResult> drainRouter(
    PharoahRouter routerX,
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

  Future<void> forward(HttpResponse httpRes, Response res) {
    final body = res.body;
    if (body == null) {
      throw PharoahException('Body value must always be present');
    }

    httpRes.headers.add('X-Powered-By', 'Pharoah');
    httpRes.headers.add(HttpHeaders.dateHeader, DateTime.now().toUtc());
    final contentLength = res.contentLength;
    if (contentLength != null) {
      httpRes.headers.add(HttpHeaders.contentLengthHeader, contentLength);
    }

    // TODO(codekeyz) research on handling chunked-encoding
    //
    //var coding = response.headers['transfer-encoding']?.join();
    // if (coding != null && !equalsIgnoreAsciiCase(coding, 'identity')) {
    //   respBody = Body(chunkedCoding.decoder.bind(body!.read()));
    //   response.headers.set(HttpHeaders.transferEncodingHeader, 'chunked');
    // } else if (response.statusCode >= 200 &&
    //     response.statusCode != 204 &&
    //     response.statusCode != 304 &&
    //     respBody.contentLength == null &&
    //     mimeType != 'multipart/byteranges') {
    //   // If the response isn't chunked yet and there's no other way to tell its
    //   // length, enable `dart:io`'s chunked encoding.
    //   response.headers.set(HttpHeaders.transferEncodingHeader, 'chunked');
    // }

    return httpRes.addStream(body.read()).then((value) => httpRes.close());
  }

  @override
  Future<void> shutdown() async {
    await _server.close();
  }
}
