import 'dart:convert';
import 'dart:io';

import 'package:http_parser/http_parser.dart';

import '../shelf_interop/shelf.dart' as shelf;
import '../utils/exceptions.dart';
import '../view/view.dart';
import 'cookie.dart';
import 'message.dart';
import 'request.dart';
import 'response.dart';

class $Response extends Message<shelf.Body?> implements Response {
  final bool ended;

  final int statusCode;

  final List<Cookie> _cookies = [];

  ViewRenderData? viewToRender;

  DateTime? _expiresCache;

  /// The date and time after which the $Response's data should be considered
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

  /// The date and time the source of the $Response's data was last modified.
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

  /// Constructs an HTTP $Response with the given [statusCode].
  ///
  /// [statusCode] must be greater than or equal to 100.
  ///
  /// {@macro shelf_$Response_body_and_encoding_param}
  $Response({
    shelf.Body? body,
    int? statusCode,
    this.ended = false,
    Map<String, dynamic> headers = const {},
  })  : statusCode = statusCode ?? HttpStatus.ok,
        super(body, headers: Map<String, dynamic>.from(headers)) {
    if (this.statusCode < 100) {
      throw PharaohException('Invalid status code: $statusCode.');
    }
  }

  @override
  $Response header(String headerKey, String headerValue) => $Response(
        headers: headers..[headerKey] = headerValue,
        body: body,
        ended: ended,
        statusCode: statusCode,
      );

  @override
  $Response type(ContentType type) => $Response(
        headers: headers..[HttpHeaders.contentTypeHeader] = type.toString(),
        body: body,
        ended: ended,
        statusCode: statusCode,
      );

  @override
  $Response status(int code) => $Response(
        statusCode: code,
        body: body,
        ended: ended,
        headers: headers,
      );

  @override
  $Response redirect(String url, [int statusCode = HttpStatus.found]) => this.end()
    ..headers[HttpHeaders.locationHeader] = url
    ..status(statusCode);

  @override
  $Response movedPermanently(String url) => redirect(url, HttpStatus.movedPermanently);

  @override
  $Response notModified({Map<String, dynamic>? headers}) {
    final existingHeaders = this.headers;
    if (headers != null) headers.forEach((key, val) => existingHeaders[key] = val);

    return $Response(
      ended: true,
      statusCode: HttpStatus.notModified,
      headers: existingHeaders
        ..removeWhere((name, _) => name.toLowerCase() == HttpHeaders.contentLengthHeader)
        ..[HttpHeaders.dateHeader] = formatHttpDate(DateTime.now()),
    );
  }

  @override
  $Response json(Object? data, {int? statusCode}) {
    statusCode ??= this.statusCode;
    if (mediaType == null) {
      headers[HttpHeaders.contentTypeHeader] = ContentType.json.toString();
    }

    late Object result;

    try {
      if (data is Set) data = data.toList();
      result = jsonEncode(data);
    } catch (_) {
      result = jsonEncode(error(_.toString()));
      statusCode = HttpStatus.internalServerError;
    }

    body = shelf.Body(result);

    return this.status(statusCode).end();
  }

  @override
  $Response notFound([String? message]) =>
      json(error(message ?? 'Not found'), statusCode: HttpStatus.notFound);

  @override
  $Response unauthorized({Object? data}) =>
      json(data ?? error('Unauthorized'), statusCode: HttpStatus.unauthorized);

  @override
  $Response internalServerError([String? message]) =>
      json(error(message ?? 'Internal Server Error'),
          statusCode: HttpStatus.internalServerError);

  @override
  $Response ok([String? data]) => this.end()
    ..headers[HttpHeaders.contentTypeHeader] = ContentType.text.toString()
    ..body = shelf.Body(data, encoding);

  @override
  $Response send(Object data) => this.end()
    ..headers[HttpHeaders.contentTypeHeader] =
        _getContentType(data, valueWhenNull: ContentType.html).toString()
    ..body = shelf.Body(data);

  @override
  $Response end() => $Response(
        body: body,
        ended: true,
        headers: headers,
        statusCode: statusCode,
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
  $Response format(Request request, Map<String, Function($Response res)> options) {
    var reqAcceptType = request.headers[HttpHeaders.acceptHeader];
    if (reqAcceptType is Iterable) reqAcceptType = reqAcceptType.join();
    final handler = options[reqAcceptType] ?? options['_'];

    if (handler == null) {
      return json(error('Not Acceptable'), statusCode: HttpStatus.notAcceptable);
    }

    return handler.call(this);
  }

  Map<String, dynamic> error(String message) => {'error': message};

  @override
  $Response cookie(
    String name,
    Object? value, [
    CookieOpts opts = const CookieOpts(),
  ]) =>
      this
        .._cookies.add(bakeCookie(name, value, opts))
        ..headers[HttpHeaders.setCookieHeader] = _cookies;

  @override
  $Response withCookie(Cookie cookie) => this
    .._cookies.add(cookie)
    ..headers[HttpHeaders.setCookieHeader] = _cookies;

  @override
  Response render(String name, [Map<String, dynamic> data = const {}]) => this.end()
    ..viewToRender = ViewRenderData(name, data)
    ..headers[HttpHeaders.contentTypeHeader] = ContentType.html.toString();
}
