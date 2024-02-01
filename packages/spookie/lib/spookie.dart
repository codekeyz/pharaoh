import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'src/http_expectation.dart';

export 'package:test/test.dart';

typedef HttpRequestHandler = Function(HttpRequest req);

abstract interface class Spookie {
  factory Spookie.fromServer(HttpServer server) =>
      _$SpookieImpl(getServerUri(server));

  factory Spookie.fromUri(Uri uri) => _$SpookieImpl(uri);

  Spookie auth(String user, String pass);

  Spookie token(String token);

  HttpResponseExpection post(
    String path,
    Object? body, {
    Map<String, String>? headers,
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

class _$SpookieImpl implements Spookie {
  final Uri baseUri;

  _$SpookieImpl(this.baseUri) {
    _headers.clear();
  }

  Uri getUri(String path) => baseUri.replace(path: path);

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
    String path,
    Object? body, {
    Map<String, String>? headers,
  }) {
    headers = mergeHeaders(headers ?? {});

    if (body is Map && !headers.containsKey(HttpHeaders.contentTypeHeader)) {
      headers[HttpHeaders.contentTypeHeader] = 'application/json';
      body = jsonEncode(body);
    }

    return expectHttp(http.post(getUri(path), headers: headers, body: body));
  }

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

  @override
  Spookie token(String token) {
    _headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
    return this;
  }
}

class SpookieAgent {
  static Spookie? _instance;
  static HttpServer? _server;

  static Future<Spookie> create(HttpRequestHandler app) async {
    if (_instance != null) {
      await _server?.close();
      _server = null;
    }

    _server = await HttpServer.bind(InternetAddress.anyIPv4, 0)
      ..listen(app);
    return _instance = Spookie.fromServer(_server!);
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

Future<Spookie> request<T extends Object>(T app) async {
  return SpookieAgent.create((app as dynamic).handleRequest);
}
