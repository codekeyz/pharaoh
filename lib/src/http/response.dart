import 'dart:convert';
import 'dart:io';

import '../utils/exceptions.dart';
import 'body.dart';
import 'message.dart';
import 'request.dart';

abstract interface class ResponseContract {
  Response redirect(String url, [int statusCode = HttpStatus.found]);

  Response json(Object data);

  Response ok([Object? body]);

  Response notFound([Object? body]);

  Response internalServerError([Object? body]);

  Response type(ContentType type);

  Response status(int code);
}

class Response extends Message<Body> implements ResponseContract {
  late final HttpRequest _req;

  /// This is just an interface that holds the current request information
  late final $Request _reqInfo;

  HttpResponse get httpResponse => _req.response;

  int _statusCode = 200;

  int get statusCode => _statusCode;

  Response._(this._req, this._reqInfo) : super(_req, Body(null)) {
    // An adapter must not add or modify the `Transfer-Encoding` parameter, but
    // the Dart SDK sets it by default. Set this before we fill in
    // [response.headers] so that the user or Shelf can explicitly override it if
    // necessary.
    httpResponse.headers.chunkedTransferEncoding = false;
  }

  factory Response.from(HttpRequest req, $Request request) =>
      Response._(req, request);

  @override
  Response type(ContentType type) {
    updateHeaders((hds) => hds[HttpHeaders.contentTypeHeader] = type.value);
    return this;
  }

  @override
  Response status(int code) {
    _statusCode = code;
    return this;
  }

  @override
  Response redirect(
    String url, [
    int statusCode = HttpStatus.found,
  ]) {
    status(statusCode);
    updateHeaders((hds) => hds[HttpHeaders.locationHeader] = url);
    return this;
  }

  @override
  Response json(Object data) {
    body = Body(jsonEncode(data), encoding);
    updateHeaders(
      (headers) =>
          headers[HttpHeaders.contentTypeHeader] = ContentType.json.value,
    );
    return this;
  }

  @override
  Response ok([Object? object]) {
    status(200);
    body = Body(object, encoding);
    return this;
  }

  @override
  Response notFound([Object? object]) {
    status(404);
    object ??= PharoahErrorBody('Not found', _reqInfo.path, _statusCode).data;
    return json(object);
  }

  @override
  Response internalServerError([Object? object]) {
    status(500);
    object ??=
        PharoahErrorBody('Internal Server Error', _reqInfo.path, _statusCode)
            .data;
    return json(object);
  }
}
