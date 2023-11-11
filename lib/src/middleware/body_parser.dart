import 'dart:convert';
import 'dart:io';

import 'package:mime/mime.dart';

import '../http/request.dart';
import '../response.dart';
import '../router/route.dart';
import '../router/handler.dart';

class MimeType {
  static const String multiPartForm = 'multipart/form-data';
  static const String applicationFormUrlEncoded =
      'application/x-www-form-urlencoded';
  static const String applicationJson = 'application/json';
  static const String textPlain = 'text/plain';
}

Future<ReqRes> _processBody(Request req, Response res) async {
  final mimeType = req.contentType?.mimeType;
  if (mimeType == null) return (req, res);

  if (mimeType == MimeType.multiPartForm) {
    final boundary = req.contentType!.parameters['boundary']!;
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
    return (req, res);
  }

  final body = await utf8.decoder.bind(req.req).join();
  if (body.isEmpty) return (req, res);

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

  return (req, res);
}

final bodyParser = Middleware(_processBody, Route.any());
