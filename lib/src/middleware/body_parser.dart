import 'dart:convert';

import '../http/request.dart';
import '../response.dart';
import '../router/route.dart';
import '../router/handler.dart';

const _supportedMimeTypes = [
  'application/x-www-form-urlencoded',
  'application/json',
  'text/plain',
];

Future<ReqRes> _processBody(Request req, Response res) async {
  final mimeType = req.contentType?.mimeType;
  if (mimeType == null || !_supportedMimeTypes.contains(mimeType)) {
    return (req, res);
  }

  final body = await utf8.decoder.bind(req.req).join();

  switch (mimeType) {
    case 'application/x-www-form-urlencoded':
      req.body = Uri.splitQueryString(body);
      break;
    case 'application/json':
      req.body = json.decode(body);
      break;
    case 'text/plain':
      req.body = body;
      break;
    default:
  }

  return (req, res);
}

final bodyParser = Middleware(_processBody, Route.any());
