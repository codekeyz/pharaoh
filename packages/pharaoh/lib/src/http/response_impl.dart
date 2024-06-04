part of 'response.dart';

class _$ResponseImpl extends Response {
  bool ended = false;

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
  _$ResponseImpl._({
    shelf.ShelfBody? body,
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
  _$ResponseImpl header(String headerKey, String headerValue) =>
      _$ResponseImpl._(
        headers: headers..[headerKey] = headerValue,
        body: body,
        ended: ended,
        statusCode: statusCode,
      );

  @override
  _$ResponseImpl type(ContentType type) => _$ResponseImpl._(
        headers: headers..[HttpHeaders.contentTypeHeader] = type.toString(),
        body: body,
        ended: ended,
        statusCode: statusCode,
      );

  @override
  _$ResponseImpl status(int code) => _$ResponseImpl._(
        statusCode: code,
        body: body,
        ended: ended,
        headers: headers,
      );

  @override
  Response withBody(Object object) => this..body = shelf.ShelfBody(object);

  @override
  _$ResponseImpl redirect(String url, [int statusCode = HttpStatus.found]) {
    headers[HttpHeaders.locationHeader] = url;
    return this.status(statusCode).end();
  }

  @override
  _$ResponseImpl movedPermanently(String url) =>
      redirect(url, HttpStatus.movedPermanently);

  @override
  _$ResponseImpl notModified({Map<String, dynamic>? headers}) {
    final existingHeaders = this.headers;
    if (headers != null) {
      headers.forEach((key, val) => existingHeaders[key] = val);
    }

    return _$ResponseImpl._(
      ended: true,
      statusCode: HttpStatus.notModified,
      headers: existingHeaders
        ..removeWhere(
            (name, _) => name.toLowerCase() == HttpHeaders.contentLengthHeader)
        ..[HttpHeaders.dateHeader] = formatHttpDate(DateTime.now()),
    );
  }

  @override
  _$ResponseImpl json(Object? data, {int? statusCode}) {
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

    body = shelf.ShelfBody(result);

    return this.status(statusCode).end();
  }

  @override
  _$ResponseImpl notFound([String? message]) =>
      json(error(message ?? 'Not found'), statusCode: HttpStatus.notFound);

  @override
  _$ResponseImpl unauthorized({Object? data}) =>
      json(data ?? error('Unauthorized'), statusCode: HttpStatus.unauthorized);

  @override
  _$ResponseImpl internalServerError([String? message]) =>
      json(error(message ?? 'Internal Server Error'),
          statusCode: HttpStatus.internalServerError);

  @override
  _$ResponseImpl ok([String? data]) => this.end()
    ..headers[HttpHeaders.contentTypeHeader] = ContentType.text.toString()
    ..body = shelf.ShelfBody(data, encoding);

  @override
  _$ResponseImpl send(Object data) {
    return this.end()
      ..headers[HttpHeaders.contentTypeHeader] ??= ContentType.binary.toString()
      ..body = shelf.ShelfBody(data);
  }

  @override
  _$ResponseImpl end() => _$ResponseImpl._(
        body: body,
        ended: true,
        headers: headers,
        statusCode: statusCode,
      );

  @override
  _$ResponseImpl format(
    Request request,
    Map<String, Function(_$ResponseImpl res)> options,
  ) {
    var reqAcceptType = request.headers[HttpHeaders.acceptHeader];
    if (reqAcceptType is Iterable) reqAcceptType = reqAcceptType.join();

    final handler = options[reqAcceptType] ?? options['_'];

    if (handler == null) {
      return json(
        error('Not Acceptable'),
        statusCode: HttpStatus.notAcceptable,
      );
    }

    return handler.call(this);
  }

  Map<String, dynamic> error(String message) => {'error': message};

  @override
  _$ResponseImpl cookie(
    String name,
    Object? value, [
    CookieOpts opts = const CookieOpts(),
  ]) =>
      this
        .._cookies.add(bakeCookie(name, value, opts))
        ..headers[HttpHeaders.setCookieHeader] = _cookies;

  @override
  _$ResponseImpl withCookie(Cookie cookie) => this
    .._cookies.add(cookie)
    ..headers[HttpHeaders.setCookieHeader] = _cookies;

  @override
  Response render(String name, [Map<String, dynamic> data = const {}]) =>
      this.end()
        ..viewToRender = ViewRenderData(name, data)
        ..headers[HttpHeaders.contentTypeHeader] = ContentType.html.toString();
}
