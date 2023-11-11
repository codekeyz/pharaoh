import 'dart:convert';
import 'dart:io';

import 'body.dart';
import 'message.dart';

abstract interface class ResponseContract {
  Future<dynamic> redirect(String url, [int statusCode = HttpStatus.found]);

  Future<dynamic> json(Object data);

  Future<dynamic> ok([Object? object]);

  Response type(ContentType type);

  Response status(int code);
}

class Response extends Message<Body> implements ResponseContract {
  late final HttpRequest _req;
  HttpResponse get httpResponse => _req.response;

  bool _completed = false;
  int _statusCode = 200;

  bool get completed => _completed;

  Response._(this._req) : super(_req, Body(null));

  factory Response.from(HttpRequest req) => Response._(req);

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
  Future<dynamic> ok([Object? object]) async {
    body = Body(object, encoding);
    return forward();
  }

  Future<Response> forward() async {
    final response = body;
    if (response == null) throw Exception('Body value must always be present');
    if (_completed) throw Exception('Response already sent');

    updateHeaders((headers) {
      headers['X-Powered-By'] = 'Pharoah';
      headers[HttpHeaders.contentLengthHeader] = response.contentLength;
      headers[HttpHeaders.dateHeader] = DateTime.now().toUtc();
      httpResponse.headers.chunkedTransferEncoding = false;
    });

    for (final header in headers.entries) {
      httpResponse.headers.add(header.key, header.value);
    }

    httpResponse.statusCode = _statusCode;

    await httpResponse
        .addStream(response.read())
        .then((value) => httpResponse.close());
    _completed = true;
    return this;
  }
}
