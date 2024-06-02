import '../http/request.dart';
import '../http/response.dart';
import '../router/router_handler.dart';

logRequests(Request req, Response res, NextFunction next) {
  final logLines = """
-------------------------------------------------------
Path:             ${req.path}
Method:           ${req.method.name}
Content-Type      ${req.mimeType}
-------------------------------------------------------\n""";
  print(logLines);
  next();
}
