import 'dart:io';

import 'package:http_parser/http_parser.dart';
import 'package:pharaoh/pharaoh.dart';

import 'message.dart';

part 'request_impl.dart';

class RequestContext {
  static const String phar = 'phar';
  static const String auth = '$phar.auth';

  /// cookies & session
  static const String cookies = '$phar.cookies';
  static const String signedCookies = '$phar.signedcookies';
  static const String session = '$phar.session.cookie';
  static const String sessionId = '$phar.session.id';
}

HTTPMethod getHttpMethod(HttpRequest req) => switch (req.method) {
      'GET' => HTTPMethod.GET,
      'HEAD' => HTTPMethod.HEAD,
      'POST' => HTTPMethod.POST,
      'PUT' => HTTPMethod.PUT,
      'DELETE' => HTTPMethod.DELETE,
      'PATCH' => HTTPMethod.PATCH,
      'OPTIONS' => HTTPMethod.OPTIONS,
      'TRACE' => HTTPMethod.TRACE,
      _ => throw PharaohException('Method ${req.method} not yet supported')
    };

abstract class Request<T> extends Message<T> {
  late final HttpRequest actual;

  Request(super.body, {super.headers = const {}});

  Uri get uri;

  String get path;

  Map<String, dynamic> get query;

  String get ipAddr;

  String? get hostname;

  String get protocol;

  String get protocolVersion;

  dynamic get auth;

  HTTPMethod get method;

  Map<String, dynamic> get params;

  Map<String, dynamic> get headers;

  List<Cookie> get cookies;

  List<Cookie> get signedCookies;

  String? get sessionId;

  Session? get session;

  T? get body;

  Object? operator [](String name);

  void operator []=(String name, dynamic value);

  void setParams(String key, String value);
}
