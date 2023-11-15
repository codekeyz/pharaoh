import 'dart:convert';
import 'dart:io';

import '../utils/exceptions.dart';
import '../shelf_interop/shelf.dart' as shelf;
import '../utils/utils.dart';
import 'message.dart';
import 'request.dart';

abstract interface class $Response {
  Response redirect(String url, [int statusCode = HttpStatus.found]);

  Response end();

  Response json(Object? data);

  Response ok([String? data]);

  Response send(Object data);

  Response notFound([String? message]);

  Response internalServerError([String? message]);

  Response type(ContentType type);

  Response status(int code);
}

class Response extends Message<shelf.Body> implements $Response {
  /// This is just an interface that holds the current request information
  late final $Request _reqInfo;

  late final HttpRequest _httpReq;

  int _statusCode = 200;

  bool _ended = false;

  bool get ended => _ended;

  int get statusCode => _statusCode;

  Response._(this._httpReq, shelf.Body body) : super(_httpReq, body) {
    _reqInfo = Request.from(_httpReq);
    updateHeaders((hders) => _httpReq.response.headers
        .forEach((name, values) => hders[name] = values));
  }

  factory Response.from(HttpRequest request) => Response._(
        request,
        shelf.Body(null),
      );

  @override
  Response type(ContentType type) {
    final value = contentTypeToString(type);
    _httpReq.response.headers.set(HttpHeaders.contentTypeHeader, value);
    return Response._(_httpReq, body!);
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
  Response json(Object? data) {
    late Object result;
    try {
      result = jsonEncode(data);
    } catch (_) {
      result = jsonEncode(makeError(message: _.toString()).toJson);
    }
    return Response._(_httpReq, shelf.Body(result)).end();
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
      ..body = shelf.Body(data, encoding)
      ..status(200)
      ..end());
    return this;
  }

  @override
  Response send(Object data) {
    _updateOrThrowIfEnded((res) => res
      ..body = shelf.Body(data)
      ..end());
    return this;
  }

  @override
  Response end() {
    return Response._(_httpReq, body!).._ended = true;
  }

  void _updateOrThrowIfEnded(Function(Response res) update) {
    if (_ended) throw PharoahException('Response lifecyle already ended');
    update(this);
  }

  PharoahErrorBody makeError({required String message}) =>
      PharoahErrorBody(message, _reqInfo.path, method: _reqInfo.method);
}
