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
    final value = contentTypeToString(type);
    _httpReq.response.headers.set(HttpHeaders.contentTypeHeader, value);
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
      result = jsonEncode(data);
    } catch (_) {
      result = jsonEncode(makeError(message: _.toString()).toJson);
    }

    final response = Response._(_httpReq, shelf.Body(result));
    final contentType = headers[HttpHeaders.contentTypeHeader];
    if (contentType == null) return response.type(ContentType.json).end();
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
  Response send(Object data) => Response._(_httpReq, shelf.Body(data)).end();

  @override
  Response end() => Response._(_httpReq, body).._ended = true;

  PharaohErrorBody makeError({required String message}) =>
      PharaohErrorBody(message, _reqInfo.path, method: _reqInfo.method);
}
