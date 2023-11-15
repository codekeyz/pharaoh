import 'dart:io';
import 'package:http/http.dart' as http;

typedef TestApp = Function(HttpRequest req);

abstract interface class Tester {
  late final HttpServer _server;

  Tester._(HttpServer server) : _server = server;

  Future<http.Response> post(
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

  @override
  Future<http.Response> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) =>
      http.post(getUri(path), headers: headers, body: body);

  @override
  Future<http.Response> get(
    String path, {
    Map<String, String>? headers,
  }) =>
      http.get(getUri(path), headers: headers);
}

class TestAgent {
  static _$TesterImpl? _instance;

  static Future<Tester> create<T>(TestApp app) async {
    if (_instance != null) return _instance!;
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
  final tester = await TestAgent.create<T>((app as dynamic).handleRequest);
  return tester;
}
