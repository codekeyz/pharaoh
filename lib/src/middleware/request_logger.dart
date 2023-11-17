import '../http/request.dart';
import '../http/response.dart';
import '../router/handler.dart';

void _processBody(Request req, Response res, NextFunction next) async {
  final logLines = """
-------------------------------------------------------
Path:             ${req.path}
Method:           ${req.method.name}
Content-Type      ${req.mimeType}
-------------------------------------------------------\n""";
  print(logLines);
  next();
}

const HandlerFunc logRequests = _processBody;
