import 'dart:io';

import 'utils.dart';

mixin ResponseContract {
  Future<void> redirect(String url, [int statusCode = HttpStatus.found]);

  Future<void> json(dynamic data);

  Response type(ContentType type);

  Response status(int code);
}

class Response with ResponseContract {
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
  Future<void> json(dynamic data) async {
    type(ContentType.json);
    _res.write(encodeJson(data));
    await _res.close();
  }

  @override
  Future<void> redirect(String url, [int statusCode = HttpStatus.found]) async {
    status(statusCode);
    _res.headers.set('Location', url);
    await _res.close();
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
}
