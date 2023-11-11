import 'dart:io';

import 'utils.dart';

// ignore: constant_identifier_names
enum HTTPMethod { GET, HEAD, POST, PUT, DELETE, ALL }

abstract interface class $Request {
  String get path;

  String? get query;

  String get ipAddr;

  String get hostname;

  String get protocol;

  HTTPMethod get method;

  /// if the client doesn't provide it, please don't
  /// set any default. leave it as is
  String? get type;

  Map<String, dynamic> get headers;

  Map<String, dynamic> get params;

  Object? get body;
}

class Request implements $Request {
  final HttpRequest _req;
  final Map<String, dynamic> _headers = {};
  final Map<String, dynamic> _params = {};

  Request._(this._req) {
    _req.headers.forEach((name, values) {
      _headers[name] = values;
    });
  }

  factory Request.from(HttpRequest request) => Request._(request);

  @override
  Object? get body {
    final contentType = type;
    if (contentType == null) return null;

    // var requestBody = await utf8.decoder.bind(_req).join();
    // print('Request Body: $requestBody');
  }

  @override
  String get path => _req.uri.toString();

  /// if no contentType
  @override
  String? get type => _headers[HttpHeaders.contentTypeHeader]?.toString();

  @override
  String get ipAddr => throw UnimplementedError();

  @override
  HTTPMethod get method => getHttpMethod(_req);

  @override
  Map<String, dynamic> get headers => _headers;

  @override
  Map<String, dynamic> get params => _params;

  @override
  String? get query => null;

  @override
  String get hostname => throw UnimplementedError();

  @override
  String get protocol => throw UnimplementedError();
}
