import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

typedef TestApp = Function(HttpRequest req);

abstract interface class Tester {
  late final HttpServer _server;

  Tester._(HttpServer server) : _server = server;

  Tester auth(String user, String pass);

  Future<http.Response> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  });

  Future<http.Response> put(
    String path, {
    Map<String, String>? headers,
    Object? body,
  });

  Future<http.Response> patch(
    String path, {
    Map<String, String>? headers,
    Object? body,
  });

  Future<http.Response> delete(
    String path, {
    Map<String, String>? headers,
    Object? body,
  });

  Future<http.Response> get(
    String path, {
    Map<String, String>? headers,
  });
}

class _$TesterImpl extends Tester {
  Uri get serverUri => getServerUri(_server);

  _$TesterImpl(HttpServer server) : super._(server);

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
  Future<http.Response> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) =>
      http.post(
        getUri(path),
        headers: mergeHeaders(headers ?? {}),
        body: body,
      );

  @override
  Future<http.Response> get(
    String path, {
    Map<String, String>? headers,
  }) =>
      http.get(
        getUri(path),
        headers: mergeHeaders(headers ?? {}),
      );

  @override
  Future<http.Response> delete(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) =>
      http.delete(
        getUri(path),
        headers: mergeHeaders(headers ?? {}),
        body: body,
      );

  @override
  Future<http.Response> patch(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) =>
      http.patch(
        getUri(path),
        headers: mergeHeaders(headers ?? {}),
        body: body,
      );

  @override
  Future<http.Response> put(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) =>
      http.put(
        getUri(path),
        headers: mergeHeaders(headers ?? {}),
        body: body,
      );

  @override
  Tester auth(String user, String pass) {
    final basicAuth = base64Encode(utf8.encode('$user:$pass'));
    _headers[HttpHeaders.authorizationHeader] = 'Basic $basicAuth';
    return this;
  }
}

class TestAgent {
  static _$TesterImpl? _instance;

  static Future<Tester> create(TestApp app) async {
    if (_instance != null) {
      await _instance!._server.close();
      _instance = null;
    }

    final server = await HttpServer.bind('127.0.0.1', 0)
      ..listen(app);
    _instance = _$TesterImpl(server);
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

Future<Tester> request<T>(T app) async {
  final tester = await TestAgent.create((app as dynamic).handleRequest);
  return tester;
}
