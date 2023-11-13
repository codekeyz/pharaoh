import 'dart:io';

import '../utils/exceptions.dart';
import 'message.dart';

// ignore: constant_identifier_names
enum HTTPMethod { GET, HEAD, POST, PUT, DELETE, ALL, PATCH, OPTIONS, TRACE }

HTTPMethod getHttpMethod(HttpRequest req) {
  switch (req.method) {
    case 'GET' || 'HEAD':
      return HTTPMethod.GET;
    case 'POST':
      return HTTPMethod.POST;
    case 'PUT':
      return HTTPMethod.PUT;
    case 'DELETE':
      return HTTPMethod.DELETE;
    case 'PATCH':
      return HTTPMethod.PATCH;
    case 'OPTIONS':
      return HTTPMethod.OPTIONS;
    case 'TRACE':
      return HTTPMethod.TRACE;
    default:
      throw PharoahException('Method ${req.method} not yet supported');
  }
}

abstract interface class $Request extends Message<dynamic> {
  $Request._(super.req);

  String get path;

  String? get query;

  String get ipAddr;

  String? get hostname;

  String get protocol;

  String get protocolVersion;

  HTTPMethod get method;

  Map<String, dynamic> get params;

  /// TODO(codekeyz) implement this so that we can retrieve objects
  /// from the current request context.
  /// This can be useful to middlewares that will want to make available
  /// loggers, etc to other handlers in the route handler execution list
  ///
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

class Request extends $Request {
  final HttpRequest _req;
  final Map<String, dynamic> _params = {};
  final Map<String, dynamic> _context = {};

  Request._(this._req) : super._(_req) {
    updateHeaders((headers) {
      req.headers.forEach((name, values) {
        headers[name] = values;
      });
    });
    _params.addAll(_req.uri.queryParameters);
  }

  factory Request.from(HttpRequest request) => Request._(request);

  HttpRequest get req => _req;

  void putInContext(String key, Object object) => _context[key] = object;

  @override
  String get path => _req.uri.path;

  @override
  String get ipAddr => _req.connectionInfo?.remoteAddress.address ?? 'Unknown';

  @override
  HTTPMethod get method => getHttpMethod(_req);

  @override
  Map<String, dynamic> get params => _params;

  @override
  String? get query => _req.uri.query;

  @override
  String? get hostname => _req.headers.host;

  @override
  String get protocol => _req.requestedUri.scheme;

  @override
  String get protocolVersion => _req.protocolVersion;

  @override
  Object? operator [](String name) => _context[name];
}
