part of 'request.dart';

class RequestImpl extends Request<dynamic> {
  final Map<String, dynamic> _params = {};
  final Map<String, dynamic> _context = {};

  RequestImpl._(HttpRequest _req) : super(_req, headers: {}) {
    actual = _req;
    actual.headers.forEach((name, values) => headers[name] = values);
    headers.remove(HttpHeaders.transferEncodingHeader);
  }

  @override
  void setParams(String key, String value) => _params[key] = value;

  /// If this is non-`null` and the requested resource hasn't been modified
  /// since this date and time, the server should return a 304 Not Modified
  /// response.
  ///
  /// This is parsed from the If-Modified-Since header in [headers]. If
  /// [headers] doesn't have an If-Modified-Since header, this will be `null`.
  ///
  /// Throws [FormatException], if incoming HTTP request has an invalid
  /// If-Modified-Since header.
  @override
  DateTime? get ifModifiedSince {
    if (_ifModifiedSinceCache != null) return _ifModifiedSinceCache;
    if (!headers.containsKey('if-modified-since')) return null;
    _ifModifiedSinceCache = parseHttpDate(headers['if-modified-since']!);
    return _ifModifiedSinceCache;
  }

  DateTime? _ifModifiedSinceCache;

  @override
  Uri get uri => actual.uri;

  @override
  String get path => actual.uri.path;

  @override
  String get ipAddr => actual.connectionInfo?.remoteAddress.address ?? 'Unknown';

  @override
  HTTPMethod get method => getHttpMethod(actual);

  @override
  Map<String, dynamic> get params => _params;

  @override
  Map<String, dynamic> get query => actual.uri.queryParameters;

  @override
  String? get hostname => actual.headers.host;

  @override
  String get protocol => actual.requestedUri.scheme;

  @override
  String get protocolVersion => actual.protocolVersion;

  @override
  List<Cookie> get cookies => _context[RequestContext.cookies] ?? [];

  @override
  List<Cookie> get signedCookies => _context[RequestContext.signedCookies] ?? [];

  @override
  Session? get session => _context[RequestContext.session];

  @override
  String? get sessionId => _context[RequestContext.sessionId];

  @override
  Object? operator [](String name) => _context[name];

  @override
  void operator []=(String name, dynamic value) {
    _context[name] = value;
  }

  @override
  dynamic get auth => _context[RequestContext.auth];

  set auth(dynamic value) => _context[RequestContext.auth] = value;
}
