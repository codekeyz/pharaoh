import 'dart:convert';
import 'dart:io';

import 'package:mime/mime.dart';

import '../http/request.dart';
import '../http/response.dart';
import '../http/router.dart';

sealed class MimeType {
  static const String multiPartForm = 'multipart/form-data';
  static const String applicationFormUrlEncoded =
      'application/x-www-form-urlencoded';
  static const String applicationJson = 'application/json';
  static const String textPlain = 'text/plain';
}

bodyParser(Request req, Response res, NextFunction next) async {
  final mimeType = req.mediaType?.mimeType;
  if (mimeType == null || req.actual.contentLength == 0) {
    return next(req..body = null);
  }

  if (mimeType == MimeType.multiPartForm) {
    final boundary = req.mediaType!.parameters['boundary'];
    if (boundary == null) return next(req..body = null);

    final parts = MimeMultipartTransformer(boundary).bind(req.actual);
    final dataBag = <String, String>{};

    await for (final part in parts) {
      final header = HeaderValue.parse(part.headers['content-disposition']!);
      final name = header.parameters['name']!;
      final filename = header.parameters['filename'];
      if (filename != null) break;
      dataBag[name] = await utf8.decodeStream(part);
    }

    return next(req..body = dataBag);
  }

  final buffer = StringBuffer();
  await for (final chunk in utf8.decoder.bind(req.actual)) {
    if (chunk.isEmpty) return next(req..body = null);
    buffer.write(chunk);
  }
  final body = buffer.toString();

  switch (mimeType) {
    case MimeType.applicationFormUrlEncoded:
      req.body = Uri.splitQueryString(Uri.decodeFull(body));
      break;
    case MimeType.applicationJson:
      if (body.isNotEmpty) req.body = json.decode(body);
      break;
    case MimeType.textPlain:
      req.body = body;
      break;
  }

  next(req);
}
