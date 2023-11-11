import 'dart:io';

import 'utils.dart';

abstract interface class ResponseContract {
  Future<dynamic> redirect(String url, [int statusCode = HttpStatus.found]);

  Future<dynamic> json(Object data);

  Future<dynamic> ok([Object? object]);

  Response type(ContentType type);

  Response status(int code);
}

class Response implements ResponseContract {
  final HttpRequest _req;

  HttpResponse get _res {
    /// TODO: be able to tell if response stream is closed
    return _req.response;
  }

  Response._(this._req) {
    type(ContentType.json);
  }

  factory Response.from(HttpRequest req) {
    return Response._(req);
  }

  @override
  Future<dynamic> json(Object data) async {
    type(ContentType.json);
    _res.write(encodeJson(data));
    return await flushAndClose(_res);
  }

  @override
  Future<dynamic> redirect(
    String url, [
    int statusCode = HttpStatus.found,
  ]) async {
    status(statusCode);
    _res.headers.set('Location', url);
    return await flushAndClose(_res);
  }

  @override
  Response type(ContentType type) {
    _res.headers.contentType = type;
    return this;
  }

  @override
  Response status(int code) {
    _res.statusCode = code;
    return this;
  }

  @override
  Future<dynamic> ok([Object? object]) async {
    status(HttpStatus.ok);
    if (object != null) {
      type(ContentType.text);
      _res.write(object);
    }
    return await flushAndClose(_res);
  }

  Future<Response> flushAndClose(HttpResponse response) async {
    await _res.flush();
    await _res.close();
    return this;
  }
}
