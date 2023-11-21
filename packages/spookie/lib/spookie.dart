import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'src/http_expectation.dart';

export 'package:test/test.dart';

typedef TestApp = Function(HttpRequest req);

abstract interface class Spookie {
  late final HttpServer _server;

  Spookie._(HttpServer server) : _server = server;

  Spookie auth(String user, String pass);

  HttpResponseExpection post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  });

  HttpResponseExpection put(
    String path, {
    Map<String, String>? headers,
    Object? body,
  });

  HttpResponseExpection patch(
    String path, {
    Map<String, String>? headers,
    Object? body,
  });

  HttpResponseExpection delete(
    String path, {
    Map<String, String>? headers,
    Object? body,
  });

  HttpResponseExpection get(
    String path, {
    Map<String, String>? headers,
  });
}

class _$SpookieImpl extends Spookie {
  Uri get serverUri => getServerUri(_server);

  _$SpookieImpl(super.server) : super._() {
    _headers.clear();
  }

  Uri getUri(String path) => Uri.parse('$serverUri$path');

  final Map<String, String> _headers = {};

  Map<String, String> mergeHeaders(Map<String, String> headers) {
    final map = Map<String, String>.from(_headers);
    for (final key in headers.keys) {
      final value = headers[key];
      if (value != null) map[key] = value;
    }
    return map;
  }

  @override
  HttpResponseExpection post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) =>
      expectHttp(
        http.post(getUri(path),
            headers: mergeHeaders(headers ?? {}), body: body),
      );

  @override
  HttpResponseExpection get(
    String path, {
    Map<String, String>? headers,
  }) =>
      expectHttp(
        http.get(getUri(path), headers: mergeHeaders(headers ?? {})),
      );

  @override
  HttpResponseExpection delete(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) =>
      expectHttp(
        http.delete(getUri(path),
            headers: mergeHeaders(headers ?? {}), body: body),
      );

  @override
  HttpResponseExpection patch(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) =>
      expectHttp(
        http.patch(getUri(path),
            headers: mergeHeaders(headers ?? {}), body: body),
      );

  @override
  HttpResponseExpection put(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) =>
      expectHttp(
        http.put(getUri(path),
            headers: mergeHeaders(headers ?? {}), body: body),
      );

  @override
  Spookie auth(String user, String pass) {
    final basicAuth = base64Encode(utf8.encode('$user:$pass'));
    _headers[HttpHeaders.authorizationHeader] = 'Basic $basicAuth';
    return this;
  }
}

class SpookieAgent {
  static _$SpookieImpl? _instance;

  static Future<Spookie> create(TestApp app) async {
    if (_instance != null) {
      await _instance!._server.close();
      _instance = null;
    }

    final server = await HttpServer.bind('127.0.0.1', 0)
      ..listen(app);
    _instance = _$SpookieImpl(server);
    return _instance!;
  }
}

Uri getServerUri(HttpServer server) {
  if (server.address.isLoopback) {
    return Uri(scheme: 'http', host: 'localhost', port: server.port);
  }
  // IPv6 addresses in URLs need to be enclosed in square brackets to avoid
  // URL ambiguity with the ":" in the address.
  if (server.address.type == InternetAddressType.IPv6) {
    return Uri(
      scheme: 'http',
      host: '[${server.address.address}]',
      port: server.port,
    );
  }

  return Uri(scheme: 'http', host: server.address.address, port: server.port);
}

Future<Spookie> request<T>(T app) async {
  final tester = await SpookieAgent.create((app as dynamic).handleRequest);
  return tester;
}
