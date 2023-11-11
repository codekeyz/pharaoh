import 'dart:io';

import 'utils.dart';

// ignore: constant_identifier_names
enum HTTPMethod { GET, HEAD, POST, PUT, DELETE, ALL }

abstract interface class $Request {
  String get path;

  String? get query;

  String get ipAddr;

  String? get hostname;

  String get protocol;

  HTTPMethod get method;

  String? get type;

  Map<String, dynamic> get headers;

  Map<String, dynamic> get params;

  Object? get body;
}

class Request implements $Request {
  final HttpRequest _req;
  final Map<String, dynamic> _headers = {};
  final Map<String, dynamic> _params = {};

  Object? _body;

  Request._(this._req) {
    _req.headers.forEach((name, values) {
      _headers[name] = values;
    });
    _params.addAll(_req.uri.queryParameters);
  }

  factory Request.from(HttpRequest request) => Request._(request);

  @override
  Object? get body => _body;

  @override
  String get path => _req.uri.path;

  @override
  String? get type => _headers[HttpHeaders.contentTypeHeader]?.toString();

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
}
