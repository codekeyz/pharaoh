import 'dart:io';

import 'package:mason_logger/mason_logger.dart';

import '../pharaoh.dart';
import 'http/request.dart';
import 'http/response.dart';
import 'middleware/body_parser.dart';
import 'router/handler.dart';
import 'router/route.dart';
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
  Pharaoh use(MiddlewareFunc reqResNext, [Route? route]) {
    _router.use(reqResNext, route);
    return this;
  }

  @override
  Pharaoh useOnPath(String path, RouteHandler handler) {
    final route = Route(path, [HTTPMethod.ALL]);

    if (handler.runtimeType == PharoahRouter) {
      final subRouter = (handler as PharoahRouter).prefix(path);

      _router.use((req, res, next) async {
        await drainRouter(subRouter, (req: req, res: res));

        next();
      }, route);
      return this;
    }

    MiddlewareFunc func = switch (handler.runtimeType) {
      Middleware => handler.handler,
      RequestHandler => (req, res, _) => handler.handler(req, res),
      Type() => throw PharoahException.value(
          'RouteHandler type not known', handler.runtimeType),
    };

    _router.use(func, route);
    return this;
  }

  @override
  Future<Pharaoh> listen([int? port]) async {
    port ??= 3000;
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

    final req = Request.from(httpReq);
    final result =
        await drainRouter(_router, (req: req, res: Response.from(req)));
    if (result.canNext == false) return;

    final res = result.reqRes.res;
    if (res.ended) {
      return forward(httpReq.response, res);
    }

    return forward(httpReq.response, res.notFound());
  }

  Future<HandlerResult> drainRouter(
    PharoahRouter routerX,
    ReqRes reqRes,
  ) async {
    try {
      return await routerX.handle(reqRes);
    } catch (e) {
      print(e);

      return (
        canNext: true,
        reqRes: (
          req: reqRes.req,
          res: Response.from(reqRes.req).internalServerError()
        )
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

    httpRes.statusCode = res.statusCode;

    for (final header in res.headers.entries) {
      final value = header.value;
      if (value != null) httpRes.headers.add(header.key, value);
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
