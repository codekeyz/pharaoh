import 'dart:convert';
import 'dart:io';

import 'package:http_parser/http_parser.dart';

import '../shelf_interop/shelf.dart';

/// [I] generic type that should either be [Request] or [Response]
/// the reason i'm accepting this type here is to be able to return instance of this as [T]
/// for methods that exist on this class.
///
/// [T] generic type that should that is set by [Request] and [Response].
/// See their implementation to understand what is happening and why that is in place.
abstract class Message<I, T> {
  final Map<String, dynamic> _headers = {};

  Map<String, dynamic> get headers => _headers;

  T? body;

  MediaType? _contentTypeCache;

  Message(HttpRequest? req, [T? value]) : body = value;

  I updateHeaders(void Function(Map<String, dynamic> headers) update) {
    _contentTypeCache = null;
    update(_headers);
    return this as I;
  }

  /// This is parsed from the Content-Type header in [headers]. It contains only
  /// the MIME type, without any Content-Type parameters.
  ///
  /// If [headers] doesn't have a Content-Type header, this will be `null`.
  MediaType? get mediaType {
    if (_contentTypeCache != null) return _contentTypeCache;
    var type = headers[HttpHeaders.contentTypeHeader];
    if (type == null) return null;
    if (type is Iterable) type = type.join(';');
    return _contentTypeCache = MediaType.parse(type);
  }

  String? get mimeType => mediaType?.mimeType;

  /// The encoding of the message body.
  ///
  /// This is parsed from the "charset" parameter of the Content-Type header in
  /// [headers].
  ///
  /// If [headers] doesn't have a Content-Type header or it specifies an
  /// encoding that `dart:convert` doesn't support, this will be `null`.
  Encoding? get encoding {
    var ctype = mediaType;
    if (ctype == null) return null;
    if (!ctype.parameters.containsKey('charset')) return null;
    return Encoding.getByName(ctype.parameters['charset']);
  }

  int? get contentLength {
    final content = body;
    return content is Body ? content.contentLength : null;
  }
}
