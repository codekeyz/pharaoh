import 'dart:convert';
import 'dart:io';

import '../utils/exceptions.dart';
import '../shelf_interop/shelf.dart';
import 'message.dart';
import 'request.dart';

abstract interface class $Response {
  Response redirect(String url, [int statusCode = HttpStatus.found]);

  Response end();

  Response json(Object data);

  Response ok([String? data]);

  Response send(Object data);

  Response notFound([String? message]);

  Response internalServerError([String? message]);

  Response type(ContentType type);

  Response status(int code);
}

class Response extends Message<Body> implements $Response {
  /// This is just an interface that holds the current request information
  late final $Request _reqInfo;

  int _statusCode = 200;

  bool _ended = false;

  bool get ended => _ended;

  int get statusCode => _statusCode;

  Response._(this._reqInfo) : super(null, Body(null));

  factory Response.from($Request request) => Response._(request);

  @override
  Response type(ContentType type) {
    _updateOrThrowIfEnded((res) => res.updateHeaders(
        (hds) => hds[HttpHeaders.contentTypeHeader] = type.value));
    return this;
  }

  @override
  Response status(int code) {
    _updateOrThrowIfEnded((res) => res._statusCode = code);
    return this;
  }

  @override
  Response redirect(String url, [int statusCode = HttpStatus.found]) {
    _updateOrThrowIfEnded(
      (res) => res
        ..status(statusCode)
        ..updateHeaders((hds) => hds[HttpHeaders.locationHeader] = url)
        ..end(),
    );
    return this;
  }

  @override
  Response json(Object data) {
    try {
      data = jsonEncode(data);
    } catch (_) {
      internalServerError(_.toString());
      return this;
    }

    _updateOrThrowIfEnded((res) => res
      ..type(ContentType.json)
      ..body = Body(data, encoding)
      ..end());
    return this;
  }

  @override
  Response notFound([String? message]) {
    _updateOrThrowIfEnded((res) => res
        .status(404)
        .json(makeError(message: message ?? 'Not found').toJson));
    return this;
  }

  @override
  Response internalServerError([String? message]) {
    _updateOrThrowIfEnded((res) => res
        .status(500)
        .json(makeError(message: message ?? 'Internal Server Error').toJson));
    return this;
  }

  @override
  Response ok([String? data]) {
    _updateOrThrowIfEnded((res) => res
      ..type(ContentType.text)
      ..body = Body(data, encoding)
      ..status(200)
      ..end());
    return this;
  }

  @override
  Response send(Object data) {
    _updateOrThrowIfEnded((res) => res
      ..body = Body(data)
      ..end());
    return this;
  }

  @override
  Response end() {
    _ended = true;
    return this;
  }

  void _updateOrThrowIfEnded(Function(Response res) update) {
    if (_ended) throw PharoahException('Response lifecyle already ended');
    update(this);
  }

  PharoahErrorBody makeError({required String message}) =>
      PharoahErrorBody(message, _reqInfo.path, method: _reqInfo.method);
}
