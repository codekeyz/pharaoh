import 'dart:convert';
import 'dart:io';

import 'package:http_parser/http_parser.dart';

import '../utils.dart';

// ignore: constant_identifier_names
enum HTTPMethod { GET, HEAD, POST, PUT, DELETE, ALL }

abstract interface class $Request {
  String get path;

  String? get query;

  String get ipAddr;

  String? get hostname;

  String get protocol;

  HTTPMethod get method;

  MediaType? get contentType;

  Encoding? get encoding;

  Map<String, dynamic> get headers;

  Map<String, dynamic> get params;

  Object? get body;

  /// Use this to get objects from the current request context
  /// Middlewares can make available extra stuffs eg: Files during
  /// a file upload.
  /// Example:
  /// ```dart
  /// final files = req['files'];
  /// print(result);
  /// ```
  Object? operator [](String name);
}

class Request implements $Request {
  final HttpRequest _req;
  final Map<String, dynamic> _headers = {};
  final Map<String, dynamic> _params = {};
  final Map<String, dynamic> _context = {};
  Object? _body;

  HttpRequest get req => _req;

  Request._(this._req) {
    _req.headers.forEach((name, values) {
      _headers[name] = values;
    });
    _params.addAll(_req.uri.queryParameters);
  }

  factory Request.from(HttpRequest request) => Request._(request);

  @override
  Object? get body => _body;

  set body(Object? body) => _body = body;

  void putInContext(String key, Object object) => _context[key] = object;

  @override
  String get path => _req.uri.path;

  @override
  String get ipAddr => _req.connectionInfo?.remoteAddress.address ?? 'Unknown';

  @override
  HTTPMethod get method => getHttpMethod(_req);

  @override
  Map<String, dynamic> get headers => _headers;

  @override
  Map<String, dynamic> get params => _params;

  @override
  String? get query => _req.uri.query;

  @override
  String? get hostname => _req.headers.host;

  @override
  String get protocol => _req.requestedUri.scheme;

  MediaType? _contentTypeCache;

  @override
  MediaType? get contentType {
    if (_contentTypeCache != null) return _contentTypeCache;
    var type = _headers[HttpHeaders.contentTypeHeader];
    if (type == null) return null;
    if (type is Iterable) type = type.join(';');
    return _contentTypeCache = MediaType.parse(type);
  }

  /// The encoding of the message body.
  ///
  /// This is parsed from the "charset" parameter of the Content-Type header in
  /// [headers].
  ///
  /// If [headers] doesn't have a Content-Type header or it specifies an
  /// encoding that `dart:convert` doesn't support, this will be `null`.
  @override
  Encoding? get encoding {
    var ctype = contentType;
    if (ctype == null) return null;
    if (!ctype.parameters.containsKey('charset')) return null;
    return Encoding.getByName(ctype.parameters['charset']);
  }

  @override
  Object? operator [](String name) => _context[name];
}
