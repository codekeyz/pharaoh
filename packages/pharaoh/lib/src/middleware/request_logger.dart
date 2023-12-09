import '../http/request_impl.dart';
import '../http/response_impl.dart';
import '../router/router_handler.dart';

void _logRequest($Request req, $Response res, NextFunction next) async {
  final logLines = """
-------------------------------------------------------
Path:             ${req.path}
Method:           ${req.method.name}
Content-Type      ${req.mimeType}
-------------------------------------------------------\n""";
  print(logLines);
  next();
}

const Middleware logRequests = _logRequest;
