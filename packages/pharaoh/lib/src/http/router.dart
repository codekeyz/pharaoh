import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http_parser/http_parser.dart';
import 'package:meta/meta.dart';
import 'package:spanner/spanner.dart';
import 'package:spanner/src/tree/tree.dart' show BASE_PATH;

import '../middleware/body_parser.dart';
import '../middleware/session_mw.dart';
import '../shelf_interop/shelf.dart' as shelf;
import '../utils/exceptions.dart';
import '../view/view.dart';

import 'request.dart';
import 'response.dart';

part 'router/router_contract.dart';
part 'router/router_handler.dart';

typedef PharaohError = ({Object exception, StackTrace trace});

typedef OnErrorCallback = FutureOr<Response> Function(
  PharaohError error,
  Request req,
  Response res,
);

abstract class Pharaoh implements RouterContract {
  static _$GroupRouter get router => _$GroupRouter();

  factory Pharaoh() => _$PharaohImpl();

  static ViewEngine? viewEngine;

  void onError(OnErrorCallback onError);

  void useSpanner(Spanner spanner);

  void useRequestHook(RequestHook hook);

  void group(String path, _$GroupRouter router);

  Uri get uri;

  Future<Pharaoh> listen({int port = 3000});

  @visibleForTesting
  void handleRequest(HttpRequest httpReq);

  Future<void> shutdown();
}

class _$PharaohImpl extends RouterContract
    with RouteDefinitionMixin
    implements Pharaoh {
  late final HttpServer _server;

  OnErrorCallback? _onErrorCb;

  final List<RequestHook> _requestHooks = [
    sessionPreResponseHook,
    viewRenderHook,
  ];

  _$PharaohImpl() {
    useSpanner(Spanner());
    use(bodyParser);
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
  Future<Pharaoh> listen({int port = 3000}) async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port, shared: true)
      ..autoCompress = true;
    _server.listen(handleRequest);

    stdout.writeln(
        'Server started on PORT: ${_server.port} -> ${uri.scheme}://localhost:${_server.port}');
    return this;
  }

  Future<void> handleRequest(HttpRequest httpReq) async {
    // An adapter must not add or modify the `Transfer-Encoding` parameter, but
    // the Dart SDK sets it by default. Set this before we fill in
    // [response.headers] so that the user or Shelf can explicitly override it if
    // necessary.
    httpReq.response.headers.chunkedTransferEncoding = false;
    httpReq.response.headers.clear();

    final request = Request.from(httpReq);
    final response = Response.create();
    late PharaohError requestError;

    try {
      final result = await resolveAndExecuteHandlers(request, response);
      return forward(httpReq, result.res);
    } catch (error, trace) {
      requestError = (exception: error, trace: trace);
    }

    if (_onErrorCb == null) {
      return forward(
        httpReq,
        response.json(
          {
            'error': requestError.exception.toString(),
            'trace': requestError.trace.toString()
          },
          statusCode: HttpStatus.internalServerError,
        ),
      );
    }

    final result = await _onErrorCb!.call(requestError, request, response);
    return forward(httpReq, result);
  }

  Future<ReqRes> resolveAndExecuteHandlers(Request req, Response res) async {
    ReqRes reqRes = (req: req, res: res);

    @pragma('vm:prefer-inline')
    Response routeNotFound() => res.notFound("Route not found: ${req.path}");

    final routeResult = spanner.lookup(req.method, req.uri);
    final resolvedHandlers = routeResult?.values ?? const [];
    if (routeResult == null || resolvedHandlers.isEmpty) {
      return reqRes.merge(routeNotFound());
    }

    if (routeResult.params.isNotEmpty) {
      req.params.addAll(routeResult.params);
    }

    for (final hook in _requestHooks.whereNot((e) => e.onBefore == null)) {
      reqRes = await hook.onBefore!.call(req, reqRes.res);
    }

    reqRes = await executeHandlers(resolvedHandlers, reqRes);
    if (!reqRes.res.ended) reqRes = reqRes.merge(routeNotFound());

    for (final hook in _requestHooks.whereNot((e) => e.onAfter == null)) {
      reqRes = await hook.onAfter!.call(reqRes.req, reqRes.res);
    }

    return reqRes;
  }

  Future<void> forward(HttpRequest request, Response res_) async {
    var coding = res_.headers[HttpHeaders.transferEncodingHeader];

    final statusCode = res_.statusCode;
    request.response.statusCode = statusCode;

    if (coding != null && !equalsIgnoreAsciiCase(coding, 'identity')) {
      // If the response is already in a chunked encoding, de-chunk it because
      // otherwise `dart:io` will try to add another layer of chunking.
      //
      // TODO(codekeyz): Do this more cleanly when sdk#27886 is fixed.
      final newStream = chunkedCoding.decoder.bind(res_.body!.read());
      res_.body = shelf.ShelfBody(newStream);
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

    final responseHeaders = res_.headers;
    if (responseHeaders.isNotEmpty) {
      for (final key in responseHeaders.keys) {
        request.response.headers.add(key, responseHeaders[key]);
      }
    }

    if (!responseHeaders.containsKey(_XPoweredByHeader)) {
      request.response.headers.add(_XPoweredByHeader, 'Pharaoh');
    }

    if (!responseHeaders.containsKey(HttpHeaders.dateHeader)) {
      request.response.headers.add(
        HttpHeaders.dateHeader,
        DateTime.now().toUtc(),
      );
    }
    if (!responseHeaders.containsKey(HttpHeaders.contentLengthHeader) &&
        res_.contentLength != null) {
      request.response.headers.add(
        HttpHeaders.contentLengthHeader,
        res_.contentLength!,
      );
    }

    final body = res_.body;
    final response = request.response;
    if (body == null) return response.close();
    return response.addStream(body.read()).then((_) => response.close());
  }

  @override
  Future<void> shutdown() async => _server.close();

  @override
  void onError(OnErrorCallback errorCb) => _onErrorCb = errorCb;

  @override
  void useRequestHook(RequestHook hook) => _requestHooks.add(hook);

  @override
  void group(String path, _$GroupRouter router) {
    spanner.attachNode(path, router.spanner.root);
  }
}

const _XPoweredByHeader = 'X-Powered-By';

class _$GroupRouter extends RouterContract with RouteDefinitionMixin {
  _$GroupRouter() {
    useSpanner(Spanner());
  }
}
