import 'dart:convert';
import 'dart:io';

import 'package:pharaoh/pharaoh.dart';
import 'package:http_parser/http_parser.dart';

import '../shelf_interop/shelf.dart' as shelf;

import 'message.dart';

part 'response_impl.dart';

abstract class Response extends Message<shelf.ShelfBody?> {
  Response(super.body, {super.headers = const {}});

  /// Constructs an HTTP Response
  static Response create({
    int? statusCode,
    Object? body,
    Encoding? encoding,
    Map<String, dynamic>? headers,
  }) {
    return ResponseImpl._(
      body: body == null ? null : ShelfBody(body),
      ended: false,
      statusCode: statusCode,
      headers: headers ?? {},
    );
  }

  Response header(String headerKey, String headerValue);

  /// Creates a new cookie setting the name and value.
  ///
  /// [name] and [value] must be composed of valid characters according to RFC
  /// 6265.
  Response cookie(String name, Object? value,
      [CookieOpts opts = const CookieOpts()]);

  Response withCookie(Cookie cookie);

  Response type(ContentType type);

  Response status(int code);

  Response withBody(Object object);

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

  bool get ended;

  int get statusCode;

  ViewRenderData? get viewToRender;
}
