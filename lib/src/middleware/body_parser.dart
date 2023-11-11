import '../request.dart';
import '../response.dart';
import '../router/route.dart';
import '../router/handler.dart';

Future<ReqRes> _processBody(Request req, Response res) async {
  print('Body parser middleware was called');

  return (req, res);
}

final bodyParser = Middleware(_processBody, Route.any());
