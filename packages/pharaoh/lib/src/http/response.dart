import 'dart:io';
import 'cookie.dart';

final applicationOctetStreamType = ContentType('application', 'octet-stream');

abstract interface class Response {
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
  Response json(Object? data);

  Response ok([String? data]);

  Response send(Object data);

  Response notModified({Map<String, dynamic>? headers});

  Response format(Map<String, Function(Response res)> data);

  Response notFound([String? message]);

  Response unauthorized({Object? data});

  Response redirect(String url, [int statusCode = HttpStatus.found]);

  Response movedPermanently(String url);

  Response internalServerError([String? message]);

  Response render(String name, [Map<String, dynamic> data]);

  Response end();
}
