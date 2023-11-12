import '../http/request.dart';
import '../http/response.dart';
import '../router/handler.dart';

Future<ReqRes> _processBody(Request req, Response _) async {
  final logLines = """
-------------------------------------------------------
Path:             ${req.path}
Params:           ${req.method.name}
Content-Type      ${req.mimeType}
-------------------------------------------------------\n""";
  print(logLines);
  return (req, _);
}

HandlerFunc logRequests = _processBody;
