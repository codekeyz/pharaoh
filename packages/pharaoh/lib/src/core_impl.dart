part of 'core.dart';

class _$PharaohImpl extends RouterContract with RouteDefinitionMixin implements Pharaoh {
  late final HttpServer _server;
  late final Logger _logger;

  final List<ReqResHook> _preResponseHooks = [
    sessionPreResponseHook,
  ];

  _$PharaohImpl() : _logger = Logger() {
    useSpanner(Spanner());
    use(bodyParser);
  }

  @override
  RouterContract router() => GroupRouter();

  @override
  List<RouteEntry> get routes => spanner.routes;

  @override
  String get routeStr => spanner.routeStr;

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
  Pharaoh group(final String path, final RouterContract router) {
    if (router is! GroupRouter) {
      throw PharaohException.value('Router is not an instance of GroupRouter');
    }
    router.commit(path, spanner);
    return this;
  }

  @override
  Future<Pharaoh> listen({int port = 3000}) async {
    final progress = _logger.progress('Starting server');

    try {
      _server = await HttpServer.bind('0.0.0.0', port, shared: true)
        ..autoCompress = true;
      _server.listen(handleRequest);
      progress.complete('Server start on PORT: ${_server.port} -> ${uri.toString()}');
    } catch (e) {
      final errMsg = (e as dynamic).message ?? 'An occurred while starting server';
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

    final req = $Request.from(httpReq);
    final res = $Response.from(httpReq);

    try {
      final result = await resolveAndExecuteHandlers(req, res);
      await forward(httpReq, result.res);
    } on PharaohValidationError catch (e) {
      await forward(
        httpReq,
        res.status(422).json(res.makeError(message: e.toString())),
      );
    } catch (e) {
      await forward(httpReq, res.internalServerError(e.toString()));
    }
  }

  Future<ReqRes> resolveAndExecuteHandlers($Request req, $Response res) async {
    ReqRes reqRes = (req: req, res: res);

    Response routeNotFound() => res.notFound("Route not found: ${req.path}");

    final routeResult = spanner.lookup(req.method, req.path);
    if (routeResult == null || routeResult.handlers.isEmpty) {
      return reqRes.merge(routeNotFound());
    }

    /// update request params with params resolved from spanner
    for (final param in routeResult.params.entries) {
      req.params[param.key] = param.value;
    }

    final chainedHandlers = routeResult.handlers.reduce((a, b) => a.chain(b));
    final result = await HandlerExecutor(chainedHandlers).execute(reqRes);
    reqRes = result.reqRes;

    for (final job in _preResponseHooks) {
      reqRes = await Future.microtask(() => job(reqRes));
    }

    if (!reqRes.res.ended) {
      return reqRes.merge(routeNotFound());
    }

    return reqRes;
  }

  Future<void> forward(HttpRequest request, $Response res_) async {
    var coding = res_.headers['transfer-encoding'];

    final statusCode = res_.statusCode;
    if (coding != null && !equalsIgnoreAsciiCase(coding, 'identity')) {
      // If the response is already in a chunked encoding, de-chunk it because
      // otherwise `dart:io` will try to add another layer of chunking.
      //
      // TODO(codekeyz): Do this more cleanly when sdk#27886 is fixed.
      final newStream = chunkedCoding.decoder.bind(res_.body!.read());
      res_ = $Response.from(request)..body = shelf.Body(newStream);
      request.headers.set(HttpHeaders.transferEncodingHeader, 'chunked');
    } else if (statusCode >= 200 &&
        statusCode != 204 &&
        statusCode != 304 &&
        res_.contentLength == null &&
        res_.mimeType != 'multipart/byteranges') {
      // If the response isn't chunked yet and there's no other way to tell its
      // length, enable `dart:io`'s chunked encoding.
      request.response.headers.set(HttpHeaders.transferEncodingHeader, 'chunked');
    }

    // headers to write to the response
    final hders = res_.headers;

    hders.forEach((key, value) => request.response.headers.add(key, value));

    if (!hders.containsKey(_XPoweredByHeader)) {
      request.response.headers.add(_XPoweredByHeader, 'Pharaoh');
    }
    if (!hders.containsKey(HttpHeaders.dateHeader)) {
      request.response.headers.add(HttpHeaders.dateHeader, DateTime.now().toUtc());
    }
    if (!hders.containsKey(HttpHeaders.contentLengthHeader)) {
      final contentLength = res_.contentLength;
      if (contentLength != null) {
        request.response.headers.add(HttpHeaders.contentLengthHeader, contentLength);
      }
    }

    request.response.statusCode = statusCode;

    return request.response
        .addStream(res_.body!.read())
        .then((_) => request.response.close());
  }

  @override
  Future<void> shutdown() async => _server.close();
}

// ignore: constant_identifier_names
const _XPoweredByHeader = 'X-Powered-By';
