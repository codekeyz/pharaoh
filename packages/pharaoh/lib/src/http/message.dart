import 'dart:convert';
import 'dart:io';

import 'package:http_parser/http_parser.dart';

import 'body.dart';

abstract class Message<T> {
  final Map<String, dynamic> headers;

  T? body;

  MediaType? _contentTypeCache;

  Message(this.body, {required this.headers});

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
