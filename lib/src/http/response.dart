import 'dart:convert';
import 'dart:io';

import '../utils/exceptions.dart';
import '../shelf_interop/shelf.dart';
import 'message.dart';
import 'request.dart';

abstract interface class ResponseContract {
  Response redirect(String url, [int statusCode = HttpStatus.found]);

  Response json(Object data);

  Response ok([Object? data]);

  Response notFound([Object? data]);

  Response internalServerError([Object? data]);

  Response type(ContentType type);

  Response status(int code);

  Response render([Object? data]);
}

class Response extends Message<Body> implements ResponseContract {
  /// This is just an interface that holds the current request information
  late final $Request _reqInfo;

  int _statusCode = 200;

  int get statusCode => _statusCode;

  Response._(this._reqInfo) : super(null, Body(null));

  factory Response.from($Request request) => Response._(request);

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
    type(ContentType.json);
    body = Body(jsonEncode(data), encoding);
    return this;
  }

  @override
  Response ok([Object? object]) {
    status(200);
    type(ContentType.text);
    body = Body(object, encoding);
    return this;
  }

  @override
  Response notFound([Object? object]) {
    status(404);
    object ??= PharoahErrorBody('Not found', _reqInfo.path, _statusCode,
            method: _reqInfo.method)
        .data;
    return json(object);
  }

  @override
  Response internalServerError([Object? object]) {
    status(500);
    object ??= PharoahErrorBody(
            'Internal Server Error', _reqInfo.path, _statusCode,
            method: _reqInfo.method)
        .data;
    return json(object);
  }

  @override
  Response render([Object? data]) {
    type(ContentType.html);
    if (data != null) body = Body(data);
    return this;
  }

  void change(Response response) {}
}
