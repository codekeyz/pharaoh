import 'dart:convert';
import 'dart:io';

import 'cookie.dart';
import 'request.dart';
import 'response_impl.dart';
import '../shelf_interop/shelf.dart' as shelf;

final applicationOctetStreamType = ContentType('application', 'octet-stream');

abstract interface class Response {
  /// Constructs an HTTP Response
  factory Response({
    int? statusCode,
    Object? body,
    Encoding? encoding,
    Map<String, dynamic> headers = const {},
  }) =>
      $Response(
        body: shelf.Body(body, encoding),
        headers: headers,
        statusCode: statusCode,
        ended: false,
      );

  Response header(String headerKey, String headerValue);

  /// Creates a new cookie setting the name and value.
  ///
  /// [name] and [value] must be composed of valid characters according to RFC
  /// 6265.
  Response cookie(String name, Object? value, [CookieOpts opts = const CookieOpts()]);

  Response withCookie(Cookie cookie);

  Response type(ContentType type);

  Response status(int code);

  /// [data] should be json-encodable
  Response json(Object? data, {int? statusCode});

  Response ok([String? data]);

  Response send(Object data);

  Response notModified({Map<String, dynamic>? headers});

  Response format(Request request, Map<String, Function(Response res)> data);

  Response notFound([String? message]);

  Response unauthorized({Object? data});

  Response redirect(String url, [int statusCode = HttpStatus.found]);

  Response movedPermanently(String url);

  Response internalServerError([String? message]);

  Response render(String name, [Map<String, dynamic> data = const {}]);

  Response end();
}
