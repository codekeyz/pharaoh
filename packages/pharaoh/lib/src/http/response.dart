import 'dart:convert';
import 'dart:io';
import 'package:http_parser/http_parser.dart';

import '../utils/exceptions.dart';
import '../shelf_interop/shelf.dart' as shelf;
import 'cookie.dart';
import 'message.dart';
import 'request.dart';

final applicationOctetStreamType = ContentType('application', 'octet-stream');

abstract interface class $Response {
  Response header(String headerKey, String headerValue);

  /// Creates a new cookie setting the name and value.
  ///
  /// [name] and [value] must be composed of valid characters according to RFC
  /// 6265.
  Response cookie(String name, Object? value, [CookieOpts opts = const CookieOpts()]);

  Response withCookie(Cookie cookie);

  Response type(ContentType type);

  Response status(int code);

  /// [data] should be json-encodable
  Response json(Object? data);

  Response ok([String? data]);

  Response send(Object data);

  Response notModified({Map<String, dynamic>? headers});

  Response format(Map<String, Function(Response res)> data);

  Response notFound([String? message]);

  Response unauthorized({Object? data});

  Response redirect(String url, [int statusCode = HttpStatus.found]);

  Response movedPermanently(String url);

  Response internalServerError([String? message]);

  Response end();
}

class Response extends Message<shelf.Body?> implements $Response {
  late final $Request _reqInfo;

  late final HttpRequest _httpReq;

  final bool ended;

  final int statusCode;

  final List<Cookie> _cookies = [];

  DateTime? _expiresCache;

  /// The date and time after which the response's data should be considered
  /// stale.
  ///
  /// This is parsed from the Expires header in [headers]. If [headers] doesn't
  /// have an Expires header, this will be `null`.
  DateTime? get expires {
    if (_expiresCache != null) return _expiresCache;
    if (!headers.containsKey('expires')) return null;
    _expiresCache = parseHttpDate(headers['expires']!);
    return _expiresCache;
  }

  /// The date and time the source of the response's data was last modified.
  ///
  /// This is parsed from the Last-Modified header in [headers]. If [headers]
  /// doesn't have a Last-Modified header, this will be `null`.
  DateTime? get lastModified {
    if (_lastModifiedCache != null) return _lastModifiedCache;
    if (!headers.containsKey('last-modified')) return null;
    _lastModifiedCache = parseHttpDate(headers['last-modified']!);
    return _lastModifiedCache;
  }

  DateTime? _lastModifiedCache;

  /// Constructs an HTTP response with the given [statusCode].
  ///
  /// [statusCode] must be greater than or equal to 100.
  ///
  /// {@macro shelf_response_body_and_encoding_param}
  Response(
    this._httpReq, {
    shelf.Body? body,
    int? statusCode,
    this.ended = false,
    Encoding? encoding,
    Map<String, dynamic>? headers,
  })  : _reqInfo = Request.from(_httpReq),
        statusCode = statusCode ?? 200,
        super(shelf.Body(body, encoding), headers: headers ?? {}) {
    if (this.statusCode < 100) {
      throw PharaohException('Invalid status code: $statusCode.');
    }
  }

  factory Response.from(HttpRequest request, {shelf.Body? body}) => Response(request);

  @override
  Response header(String headerKey, String headerValue) => Response(
        _httpReq,
        headers: headers..[headerKey] = headerValue,
        body: body,
        encoding: encoding,
        ended: ended,
        statusCode: statusCode,
      );

  @override
  Response type(ContentType type) => Response(
        _httpReq,
        headers: headers..[HttpHeaders.contentTypeHeader] = type.toString(),
        body: body,
        ended: ended,
        statusCode: statusCode,
        encoding: encoding,
      );

  @override
  Response status(int code) => Response(
        _httpReq,
        statusCode: code,
        body: body,
        ended: ended,
        encoding: encoding,
        headers: headers,
      );

  @override
  Response redirect(
    String url, [
    int statusCode = HttpStatus.found,
  ]) =>
      Response(
        _httpReq,
        statusCode: statusCode,
        headers: headers..[HttpHeaders.locationHeader] = url,
        ended: true,
      );

  @override
  Response movedPermanently(String url) => Response(
        _httpReq,
        statusCode: 301,
        headers: headers..[HttpHeaders.locationHeader] = url,
        ended: true,
      );

  @override
  Response notModified({Map<String, dynamic>? headers}) {
    final existingHeaders = this.headers;
    if (headers != null) {
      headers.forEach((key, val) => existingHeaders[key] = val);
    }

    existingHeaders.removeWhere((name, _) => name.toLowerCase() == 'content-length');
    existingHeaders[HttpHeaders.dateHeader] = formatHttpDate(DateTime.now());

    return Response(
      _httpReq,
      ended: true,
      statusCode: 304,
      headers: existingHeaders,
    );
  }

  @override
  Response json(Object? data) {
    late Object result;
    try {
      if (data is Set) data = data.toList();
      result = jsonEncode(data);
    } catch (_) {
      final errStr = jsonEncode(makeError(message: _.toString()));
      return type(ContentType.json).status(500).send(errStr);
    }

    final res = Response(
      _httpReq,
      body: shelf.Body(result),
      statusCode: statusCode,
      encoding: encoding,
      headers: headers,
      ended: true,
    );
    return mediaType == null ? res.type(ContentType.json) : res;
  }

  @override
  Response notFound([String? message]) {
    return status(404).json(makeError(message: message ?? 'Not found'));
  }

  @override
  Response unauthorized({Object? data}) {
    final error = data ?? makeError(message: 'Unauthorized');
    return status(401).json(error);
  }

  @override
  Response internalServerError([String? message]) {
    return status(500).json(makeError(message: message ?? 'Internal Server Error'));
  }

  @override
  Response ok([String? data]) => Response(
        _httpReq,
        body: shelf.Body(data, encoding),
        statusCode: statusCode,
        headers: headers,
        encoding: encoding,
        ended: true,
      ).type(ContentType.text);

  @override
  Response send(Object data) {
    final ctype = _getContentType(data, valueWhenNull: ContentType.html);
    return Response(_httpReq,
            body: shelf.Body(data),
            encoding: encoding,
            statusCode: statusCode,
            headers: headers,
            ended: true)
        .type(ctype);
  }

  @override
  Response end() {
    return Response(
      _httpReq,
      body: body,
      ended: true,
      headers: headers,
      statusCode: statusCode,
      encoding: encoding,
    );
  }

  PharaohErrorBody makeError({required String message}) => PharaohErrorBody(
        message,
        _reqInfo.path,
        method: _reqInfo.method,
      );

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

  @override
  Response format(Map<String, Function(Response res)> options) {
    var reqAcceptType = _reqInfo.headers[HttpHeaders.acceptHeader];
    if (reqAcceptType is Iterable) reqAcceptType = reqAcceptType.join();
    final handler = options[reqAcceptType] ?? options['_'];

    if (handler == null) {
      return status(HttpStatus.notAcceptable).json(makeError(message: 'Not Acceptable'));
    }

    return handler.call(this);
  }

  @override
  Response cookie(
    String name,
    Object? value, [
    CookieOpts opts = const CookieOpts(),
  ]) {
    final cookie = bakeCookie(name, value, opts);
    _cookies.add(cookie);
    headers[HttpHeaders.setCookieHeader] = _cookies;
    return this;
  }

  @override
  Response withCookie(Cookie cookie) {
    _cookies.add(cookie);
    headers[HttpHeaders.setCookieHeader] = _cookies;
    return this;
  }
}
