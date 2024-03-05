library;

import 'dart:io';

import 'core.dart';

export 'package:pharaoh/pharaoh.dart' show HTTPMethod;

@inject
abstract class ClassMiddleware extends AppInstance {
  handle(Request req, Response res, NextFunction next) {
    next();
  }

  Middleware? get handler => null;
}

@inject
abstract class ServiceProvider extends AppInstance {
  static List<Type> get defaultProviders => [];

  void boot() {}

  void register() {}
}

@inject
abstract class HTTPController extends AppInstance {
  late final Request request;

  late final Response response;

  Map<String, dynamic> get params => request.params;

  Map<String, dynamic> get queryParams => request.query;

  Map<String, dynamic> get headers => request.headers;

  Session? get session => request.session;

  get requestBody => request.body;

  bool get expectsJson {
    final headerValue =
        request.headers[HttpHeaders.acceptEncodingHeader]?.toString();
    return headerValue != null && headerValue.contains('application/json');
  }

  Response badRequest([String? message]) {
    const status = 422;
    if (message == null) return response.status(status);
    return response.json({'error': message}, statusCode: status);
  }

  Response notFound([String? message]) {
    const status = 404;
    if (message == null) return response.status(status);
    return response.json({'error': message}, statusCode: status);
  }

  Response jsonResponse(data, {int statusCode = 200}) {
    return response.json(data, statusCode: statusCode);
  }

  Response redirectTo(String url, {int statusCode = 302}) {
    return response.redirect(url, statusCode);
  }
}
