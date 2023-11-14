import 'dart:convert';
import 'dart:io';

import '../utils/exceptions.dart';
import '../shelf_interop/shelf.dart';
import 'message.dart';
import 'request.dart';

abstract interface class ResponseContract {
  Response redirect(String url, [int statusCode = HttpStatus.found]);

  Response end();

  Response json(Object data);

  Response ok([String? data]);

  Response render([Object? data]);

  Response notFound([Object? data]);

  Response internalServerError([Object? data]);

  Response type(ContentType type);

  Response status(int code);
}

class Response extends Message<Body> implements ResponseContract {
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
  Response redirect(
    String url, [
    int statusCode = HttpStatus.found,
  ]) {
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
    _updateOrThrowIfEnded((res) => res
      ..type(ContentType.json)
      ..body = Body(jsonEncode(data), encoding)
      ..end());
    return this;
  }

  @override
  Response ok([String? data]) {
    _updateOrThrowIfEnded((res) => res
      ..type(ContentType.text)
      ..body = Body(data == null ? null : jsonEncode(data), encoding)
      ..status(200)
      ..end());
    return this;
  }

  @override
  Response notFound([Object? object]) {
    _updateOrThrowIfEnded(
      (res) {
        res.status(404);

        object ??= PharoahErrorBody(
          'Not found',
          _reqInfo.path,
          res.statusCode,
          method: _reqInfo.method,
        ).data;

        res
          ..type(ContentType.json)
          ..body = Body(jsonEncode(object))
          ..end();
      },
    );
    return this;
  }

  @override
  Response internalServerError([Object? object]) {
    _updateOrThrowIfEnded(
      (res) {
        res.status(500);

        object ??= PharoahErrorBody(
          'Internal Server Error',
          _reqInfo.path,
          res.statusCode,
          method: _reqInfo.method,
        ).data;

        res
          ..type(ContentType.json)
          ..body = Body(jsonEncode(object))
          ..end();
      },
    );
    return this;
  }

  @override
  Response render([Object? data]) {
    _updateOrThrowIfEnded((res) => res
      ..type(ContentType.html).body = Body(data)
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
}
