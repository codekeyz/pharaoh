import 'dart:convert';
import 'dart:io';

import '../utils/exceptions.dart';
import 'body.dart';
import 'message.dart';
import 'request.dart';

abstract interface class ResponseContract {
  Future<dynamic> redirect(String url, [int statusCode = HttpStatus.found]);

  Future<dynamic> json(Object data);

  Future<dynamic> ok([Object? body]);

  Future<dynamic> notFound([Object? body]);

  Future<dynamic> internalServerError([Object? body]);

  Response type(ContentType type);

  Response status(int code);
}

class Response extends Message<Body> implements ResponseContract {
  late final HttpRequest _req;

  /// This is just an interface that holds the current request information
  late final $Request _reqInfo;

  HttpResponse get httpResponse => _req.response;

  bool _completed = false;
  int _statusCode = 200;

  bool get completed => _completed;

  Response._(this._req, this._reqInfo) : super(_req, Body(null));

  factory Response.from(HttpRequest req, $Request request) =>
      Response._(req, request);

  @override
  Future<dynamic> redirect(
    String url, [
    int statusCode = HttpStatus.found,
  ]) {
    status(statusCode);
    updateHeaders((hds) => hds[HttpHeaders.locationHeader] = url);
    return forward();
  }

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
  Future<dynamic> json(Object data) {
    body = Body(jsonEncode(data), encoding);
    updateHeaders(
      (headers) =>
          headers[HttpHeaders.contentTypeHeader] = ContentType.json.value,
    );
    return forward();
  }

  @override
  Future<dynamic> ok([Object? object]) async {
    status(200);
    body = Body(object, encoding);
    return forward();
  }

  @override
  Future notFound([Object? object]) {
    status(404);
    object ??= PharoahErrorBody('Not found', _reqInfo.path, _statusCode).data;
    return json(object);
  }

  @override
  Future internalServerError([Object? object]) {
    status(500);
    object ??=
        PharoahErrorBody('Internal Server Error', _reqInfo.path, _statusCode)
            .data;
    return json(object);
  }

  Future<Response> forward() async {
    final response = body;
    if (response == null) {
      throw PharoahException('Body value must always be present');
    }
    if (_completed) {
      throw PharoahException('Response already sent');
    }

    updateHeaders((headers) {
      headers['X-Powered-By'] = 'Pharoah';
      headers[HttpHeaders.contentLengthHeader] = response.contentLength;
      headers[HttpHeaders.dateHeader] = DateTime.now().toUtc();
    });

    httpResponse.statusCode = _statusCode;

    // An adapter must not add or modify the `Transfer-Encoding` parameter, but
    // the Dart SDK sets it by default. Set this before we fill in
    // [response.headers] so that the user or Shelf can explicitly override it if
    // necessary.
    httpResponse.headers.chunkedTransferEncoding = false;

    for (final header in headers.entries) {
      httpResponse.headers.add(header.key, header.value);
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

    await httpResponse
        .addStream(response.read())
        .then((value) => httpResponse.close());
    _completed = true;
    return this;
  }
}
