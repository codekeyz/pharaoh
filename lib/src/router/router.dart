// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:path_to_regexp/path_to_regexp.dart';

import '../http/body.dart';
import '../middleware/attach_necessary_headers.dart';
import '../middleware/body_parser.dart';
import '../http/response.dart';
import '../http/request.dart';
import '../utils/exceptions.dart';
import '../utils/utils.dart';
import 'handler.dart';
import 'route.dart';

const ANY_PATH = '*';

const BASE_PATH = '/';

abstract interface class RouterContract {
  List<Route> get routes;

  void get(String path, RequestHandlerFunc handler);

  void post(String path, RequestHandlerFunc handler);

  void put(String path, RequestHandlerFunc handler);

  void delete(String path, RequestHandlerFunc handler);

  void any(String path, RequestHandlerFunc handler);

  void use(HandlerFunc handler, [Route? route]);

  void group(String prefix, void Function(RouterContract router) groupCtx);
}

abstract class Router implements RouterContract {
  static Router get getInstance => _$PharoahRouter();

  Future<void> handleRequest(HttpRequest request);
}

class _$PharoahRouter extends Router {
  late final RouteGroup _group;
  final Map<String, RouteGroup> _subGroups = {};
  final List<Middleware> _lastMiddlewares = [];

  _$PharoahRouter({RouteGroup? group}) {
    if (group == null) {
      _group = RouteGroup(BASE_PATH)..add(bodyParser);
      _lastMiddlewares.add(attachNecessaryHeaders());
      return;
    }
    _group = group;
  }

  @override
  List<Route> get routes => _group.handlers.map((e) => e.route).toList();

  @override
  void get(String path, RequestHandlerFunc handler) {
    _group.add(RequestHandler(
        handler, Route(path, [HTTPMethod.GET, HTTPMethod.HEAD])));
  }

  @override
  void post(String path, RequestHandlerFunc handler) {
    _group.add(RequestHandler(handler, Route(path, [HTTPMethod.POST])));
  }

  @override
  void put(String path, RequestHandlerFunc handler) {
    _group.add(RequestHandler(handler, Route(path, [HTTPMethod.PUT])));
  }

  @override
  void delete(String path, RequestHandlerFunc handler) {
    _group.add(RequestHandler(handler, Route(path, [HTTPMethod.DELETE])));
  }

  @override
  void any(String path, RequestHandlerFunc handler) {
    _group.add(RequestHandler(handler, Route.any()));
  }

  @override
  void use(HandlerFunc handler, [Route? route]) {
    _group.add(Middleware(handler, route ?? Route.any()));
  }

  @override
  void group(String prefix, Function(RouterContract router) groupCtx) {
    if (reservedPaths.contains(prefix)) {
      throw PharoahException.value('Prefix not allowed for groups', prefix);
    }
    final router = _$PharoahRouter(group: RouteGroup(prefix));
    groupCtx(router);
    _subGroups[prefix] = router._group;
  }

  @override
  Future<void> handleRequest(HttpRequest httpReq) async {
    // An adapter must not add or modify the `Transfer-Encoding` parameter, but
    // the Dart SDK sets it by default. Set this before we fill in
    // [response.headers] so that the user or Shelf can explicitly override it if
    // necessary.
    httpReq.response.headers.chunkedTransferEncoding = false;

    final request = Request.from(httpReq);
    final response = Response.from(request);

    final handlers = _group.findHandlers(request);
    final group = findRouteGroup(request.path);
    if (group != null) {
      final subHdls = group.findHandlers(request);
      if (subHdls.isNotEmpty) handlers.addAll(subHdls);
    }

    if (hasNoRequestHandlers(handlers)) {
      // It means you don't have any request handlers
      // for this type of route.
      return forward(httpReq.response, response.notFound());
    }

    final lastHandlers = findHandlersForRequest(request, _lastMiddlewares);
    handlers.addAll(lastHandlers);

    final handlerFncs = List.from(handlers);
    ReqRes reqRes = (request, response);
    while (handlerFncs.isNotEmpty) {
      final handler = handlerFncs.removeAt(0);
      final completed = handlerFncs.isEmpty;

      try {
        final result = await processHandler(handler, reqRes);
        if (completed) return await forward(httpReq.response, reqRes.$2);
        reqRes = result;
        continue;
      } catch (e) {
        return await forward(httpReq.response, reqRes.$2.internalServerError());
      }
    }
  }

  /// TODO(codekeyz) Document this well enough so you don't
  /// forget why things are this way
  Future<ReqRes> processHandler(RouteHandler rqh, ReqRes rq) async {
    final result = await rqh.handler(rq.$1, rq.$2);
    if (result is ReqRes) return result;
    if (result is Response) return (rq.$1, result);
    if (result == null) return rq;
    return (rq.$1, Response.from(rq.$1).json(result));
  }

  RouteGroup? findRouteGroup(String path) {
    if (_subGroups.isEmpty) return null;
    final key = _subGroups.keys.firstWhereOrNull(
        (key) => path.contains(key) || pathToRegExp(key).hasMatch(path));
    return key == null ? null : _subGroups[key];
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
      httpRes.headers.add(header.key, header.value);
    }

    // var coding = response.headers['transfer-encoding']?.join();
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
}
