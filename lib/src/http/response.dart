import 'dart:io';

import '../utils.dart';
import 'message.dart';

abstract interface class ResponseContract {
  Future<dynamic> redirect(String url, [int statusCode = HttpStatus.found]);

  Future<dynamic> json(Object data);

  Future<dynamic> ok([Object? object]);

  Response type(ContentType type);

  Response status(int code);
}

class Response extends Message implements ResponseContract {
  final HttpRequest _req;
  bool _completed = false;
  int _statusCode = 200;

  bool get completed => _completed;

  HttpResponse get _res => _req.response;

  Response._(this._req) : super(_req);

  factory Response.from(HttpRequest req) => Response._(req);

  @override
  Future<dynamic> json(Object data) {
    body = data;
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
    body = object;
    return forward();
  }

  Future<Response> forward() async {
    if (_completed) throw Exception('Response already sent');

    final data = encodeJson(body);

    updateHeaders((headers) {
      headers['X-Powered-By'] = 'Pharoah';
      headers[HttpHeaders.contentLengthHeader] = data.length;
    });

    for (final header in headers.entries) {
      _res.headers.add(header.key, header.value);
    }

    _res.statusCode = _statusCode;
    _res.write(encodeJson(data));
    await _res.flush();
    await _res.close();
    _completed = true;
    return this;
  }
}
