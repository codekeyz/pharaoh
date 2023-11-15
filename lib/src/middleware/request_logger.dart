import '../http/request.dart';
import '../http/response.dart';
import '../router/handler.dart';

void _processBody(Request req, Response res, Function next) async {
  final logLines = """
-------------------------------------------------------
Path:             ${req.path}
Method:           ${req.method.name}
Content-Type      ${req.mimeType}
-------------------------------------------------------\n""";
  print(logLines);
  next();
}

const MiddlewareFunc logRequests = _processBody;
