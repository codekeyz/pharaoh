import 'dart:convert';
import 'dart:io';

import 'package:mime/mime.dart';

import '../http/request.dart';
import '../http/response.dart';
import '../router/handler.dart';

class MimeType {
  static const String multiPartForm = 'multipart/form-data';
  static const String applicationFormUrlEncoded =
      'application/x-www-form-urlencoded';
  static const String applicationJson = 'application/json';
  static const String textPlain = 'text/plain';
}

_processBody(Request req, Response res, NextFunction next) async {
  final mimeType = req.mediaType?.mimeType;
  if (mimeType == null) {
    next();
    return;
  }

  if (mimeType == MimeType.multiPartForm) {
    final boundary = req.mediaType!.parameters['boundary']!;
    final parts = MimeMultipartTransformer(boundary).bind(req.req);

    Map<String, dynamic> dataBag = {};
    await for (final part in parts) {
      final header = HeaderValue.parse(part.headers['content-disposition']!);
      final name = header.parameters['name']!;
      final filename = header.parameters['filename'];
      if (filename != null) break;
      dataBag[name] = await utf8.decodeStream(part);
    }

    req.body = dataBag;
    next();
    return;
  }

  final body = await utf8.decoder.bind(req.req).join();
  if (body.trim().isEmpty) {
    next();
    return;
  }

  switch (mimeType) {
    case MimeType.applicationFormUrlEncoded:
      req.body = Uri.splitQueryString(body);
      break;
    case MimeType.applicationJson:
      req.body = json.decode(body);
      break;
    case MimeType.textPlain:
      req.body = body;
      break;
  }

  next(req);
}

const HandlerFunc bodyParser = _processBody;
