import 'dart:async';
import 'dart:io';

import 'router.dart';

class Pharaoh {
  late final HttpServer _server;
  late final Router _router;

  RouterContract get router => _router;

  Pharaoh() : _router = PharoahRouter();

  Uri get url {
    if (_server.address.isLoopback) {
      return Uri(scheme: 'http', host: 'localhost', port: _server.port);
    }

    // IPv6 addresses in URLs need to be enclosed in square brackets to avoid
    // URL ambiguity with the ":" in the address.
    if (_server.address.type == InternetAddressType.IPv6) {
      return Uri(
        scheme: 'http',
        host: '[${_server.address.address}]',
        port: _server.port,
      );
    }

    return Uri(
      scheme: 'http',
      host: _server.address.address,
      port: _server.port,
    );
  }

  Future<Pharaoh> listen([int? port]) async {
    port ??= 3000;
    await _router.commit();
    _server = await HttpServer.bind('localhost', port);
    _server.listen(_router.handleRequest);
    print('Server start on port: $port -> ${url.toString()}');
    return this;
  }

  Future<void> shutdown() async {
    await _server.close();
  }
}
