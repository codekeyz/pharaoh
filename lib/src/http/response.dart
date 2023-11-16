import 'dart:convert';
import 'dart:io';

import '../utils/exceptions.dart';
import '../shelf_interop/shelf.dart' as shelf;
import 'message.dart';
import 'request.dart';

final applicationOctetStreamType = ContentType('application', 'octet-stream');

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

  bool _ended = false;

  bool get ended => _ended;

  Response._(this._httpReq, [shelf.Body? body])
      : _reqInfo = Request.from(_httpReq),
        super(_httpReq, body ?? shelf.Body(null)) {
    updateHeaders((hders) => _httpReq.response.headers
        .forEach((name, values) => hders[name] = values));
  }

  factory Response.from(HttpRequest request) => Response._(request);

  @override
  Response type(ContentType type) {
    _httpReq.response.headers
        .set(HttpHeaders.contentTypeHeader, type.toString());
    return Response._(_httpReq, body);
  }

  @override
  Response status(int code) {
    _httpReq.response.statusCode = code;
    return Response._(_httpReq);
  }

  @override
  Response redirect(String url, [int statusCode = HttpStatus.found]) {
    _httpReq.response.headers.set(HttpHeaders.locationHeader, url);
    return Response._(_httpReq).status(statusCode).end();
  }

  @override
  Response json(Object? data) {
    late Object result;
    try {
      if (data is Set) data = data.toList();
      result = jsonEncode(data);
    } catch (_) {
      final result = jsonEncode(makeError(message: _.toString()).toJson);
      return status(500)
        ..body = shelf.Body(result)
        ..end();
    }

    final response = Response._(_httpReq, shelf.Body(result));
    if (mediaType == null) return response.type(ContentType.json).end();
    return response.end();
  }

  @override
  Response notFound([String? message]) => Response._(_httpReq)
      .status(404)
      .json(makeError(message: message ?? 'Not found').toJson);

  @override
  Response internalServerError([String? message]) => Response._(_httpReq)
      .status(500)
      .json(makeError(message: message ?? 'Internal Server Error').toJson);

  @override
  Response ok([String? data]) =>
      Response._(_httpReq, shelf.Body(data, encoding))
          .type(ContentType.text)
          .end();

  @override
  Response send(Object data) {
    final ctype = _getContentType(data, valueWhenNull: ContentType.html);
    return type(ctype)
      ..body = shelf.Body(data)
      ..end();
  }

  @override
  Response end() {
    _ended = true;
    return this;
  }

  PharaohErrorBody makeError({required String message}) =>
      PharaohErrorBody(message, _reqInfo.path, method: _reqInfo.method);

  ContentType _getContentType(
    Object data, {
    required ContentType valueWhenNull,
  }) {
    final isBuffer = _isBuffer(data);
    final mType = mediaType;
    if (mType == null) {
      return isBuffer ? applicationOctetStreamType : valueWhenNull;
    }

    /// Always use charset :utf-8 unless
    /// we have to deal with buffers.
    final charset = isBuffer ? mType.parameters['charset'] : 'utf-8';
    return ContentType.parse('${mType.mimeType}; charset=$charset');
  }

  /// TODO research on how to tell if an object is a buffer
  bool _isBuffer(Object object) => object is! String;
}
