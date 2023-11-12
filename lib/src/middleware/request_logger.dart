import '../http/request.dart';
import '../http/response.dart';
import '../router/handler.dart';
import '../router/route.dart';

Future<ReqRes> _processBody(Request req, Response _) async {
  return (req, _);
}

Middleware logRequests([Route? route]) =>
    Middleware(_processBody, route ?? Route.any());
