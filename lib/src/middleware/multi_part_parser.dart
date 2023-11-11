import 'dart:convert';
import 'dart:io';

import 'package:mime/mime.dart';

import '../http/request.dart';
import '../response.dart';
import '../router/handler.dart';
import '../router/route.dart';

Future<ReqRes> _processBody(Request req, Response res) async {
  if (req.contentType?.mimeType != 'multipart/form-data') {
    return (req, res);
  }

  final boundary = req.contentType!.parameters['boundary']!;
  final parts = MimeMultipartTransformer(boundary).bind(req.req);

  Map<String, dynamic> dataBag = {};
  await for (final part in parts) {
    final header = HeaderValue.parse(part.headers['content-disposition']!);
    final name = header.parameters['name']!;
    final filename = header.parameters['filename'];
    if (filename != null) {
      print('files not yet handled');
      break;
    }

    dataBag[name] = await utf8.decodeStream(part);
  }

  return (req, res);
}

final multiPartParser = Middleware(_processBody, Route.any());
