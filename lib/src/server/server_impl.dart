import 'dart:io';

import 'package:mason_logger/mason_logger.dart';

import '../../pharaoh.dart';
import '../middleware/attach_necessary_headers.dart';
import '../middleware/body_parser.dart';
import '../router/handler.dart';
import '../router/route.dart';
import '../utils/exceptions.dart';

class $PharaohImpl implements Pharaoh {
  final List<RouteHandler> _routeHandlers = [];
  final List<Middleware> _lastMiddlewares = [];

  late PharoahRouter _router;
  late final HttpServer _server;
  late final Logger _logger;

  $PharaohImpl()
      : _logger = Logger(),
        _router = PharoahRouter() {
    _routeHandlers.add(bodyParser);
    _lastMiddlewares.add(attachNecessaryHeaders());
  }

  Uri get url {
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
  List<Route> get routes => _routeHandlers.map((e) => e.route).toList();

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
  Pharaoh delete(String path, RequestHandlerFunc handler) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Pharaoh get(String path, RequestHandlerFunc handler) {
    // TODO: implement get
    throw UnimplementedError();
  }

  @override
  Pharaoh post(String path, RequestHandlerFunc handler) {
    // TODO: implement post
    throw UnimplementedError();
  }

  @override
  Pharaoh put(String path, RequestHandlerFunc handler) {
    // TODO: implement put
    throw UnimplementedError();
  }

  @override
  Future<void> shutdown() async {
    await _server.close();
  }

  @override
  // TODO: implement uri
  Uri get uri => throw UnimplementedError();

  @override
  Pharaoh use(MiddlewareFunc reqResNext, [Route? route]) {
    // TODO: implement use
    throw UnimplementedError();
  }

  @override
  void useOnPath(String path, RouteHandler handler) {
    // TODO: implement useOnPath
  }

  @override
  Future<Pharaoh> listen([int? port]) async {
    port ??= 3000;
    final progress = _logger.progress('Starting server');
    _server = await HttpServer.bind('localhost', port);
    _server.listen(handleRequest);
    progress.complete('Server start on PORT: $port -> ${url.toString()}');
    return this;
  }

  void handleRequest(HttpRequest httpReq) async {
    // An adapter must not add or modify the `Transfer-Encoding` parameter, but
    // the Dart SDK sets it by default. Set this before we fill in
    // [response.headers] so that the user or Shelf can explicitly override it if
    // necessary.
    httpReq.response.headers.chunkedTransferEncoding = false;

    final request = Request.from(httpReq);
    final response = Response.from(request);

    final handlers = findHandlersForRequest(request, _routeHandlers);

    // It means you don't have any request handlers for this route.
    if (hasNoRequestHandlers(handlers)) {
      return forward(httpReq.response, response.notFound());
    }

    if (_lastMiddlewares.isNotEmpty) {
      handlers.addAll(_lastMiddlewares);
    }

    final handlerFncs = List<RouteHandler>.from(handlers);
    ReqRes reqRes = (req: request, res: response);
    while (handlerFncs.isNotEmpty) {
      final handler = handlerFncs.removeAt(0);
      final completed = handlerFncs.isEmpty;

      try {
        final data = await handler.handle(reqRes);
        reqRes = data.reqRes;
        if (!data.canNext) break;
        if (completed) return forward(httpReq.response, reqRes.res);
        continue;
      } catch (e) {
        return forward(httpReq.response, reqRes.res.internalServerError());
      }
    }
  }

  @override
  PharoahRouter router() => PharoahRouter();
}
