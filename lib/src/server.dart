import 'dart:async';
import 'dart:io';

import 'package:mason_logger/mason_logger.dart';

import 'router.dart';

class Pharaoh {
  late final HttpServer _server;
  late final Router _router;
  late final Logger _logger;

  RouterContract get router => _router;

  Pharaoh()
      : _router = PharoahRouter(),
        _logger = Logger();

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
    final progress = _logger.progress('Evaluating routes');
    await _router.commit();
    progress.update('starting server');
    _server = await HttpServer.bind('localhost', port);
    _server.listen(_router.handleRequest);
    progress.complete('Server start on PORT: $port -> ${url.toString()}');
    return this;
  }

  Future<void> shutdown() async {
    await _server.close();
  }
}
