import 'package:spanner/spanner.dart';
import '../http/request.dart';
import '../http/response.dart';
import 'handler.dart';

const basePath = '/';

abstract interface class RoutePathDefinitionContract<T> {
  T get(String path, RequestHandlerFunc hdler);

  T post(String path, RequestHandlerFunc hdler);

  T put(String path, RequestHandlerFunc hdler);

  T delete(String path, RequestHandlerFunc hdler);

  T head(String path, RequestHandlerFunc hdler);

  T patch(String path, RequestHandlerFunc hdler);

  T options(String path, RequestHandlerFunc hdler);

  T trace(String path, RequestHandlerFunc hdler);

  T use(HandlerFunc mdw, [dynamic route]);
}

class PharaohRouter implements RoutePathDefinitionContract<PharaohRouter> {
  final Router _router = Router();

  @override
  PharaohRouter delete(String path, RequestHandlerFunc hdler) {
    _router.on(HTTPMethod.DELETE, path, RequestHandler(hdler));
    return this;
  }

  @override
  PharaohRouter get(String path, RequestHandlerFunc hdler) {
    _router.on(HTTPMethod.GET, path, RequestHandler(hdler));
    _router.on(HTTPMethod.HEAD, path, RequestHandler(hdler));
    return this;
  }

  @override
  PharaohRouter head(String path, RequestHandlerFunc hdler) {
    _router.on(HTTPMethod.HEAD, path, RequestHandler(hdler));
    return this;
  }

  @override
  PharaohRouter options(String path, RequestHandlerFunc hdler) {
    _router.on(HTTPMethod.OPTIONS, path, RequestHandler(hdler));
    return this;
  }

  @override
  PharaohRouter patch(String path, RequestHandlerFunc hdler) {
    _router.on(HTTPMethod.PATCH, path, RequestHandler(hdler));
    return this;
  }

  @override
  PharaohRouter post(String path, RequestHandlerFunc hdler) {
    _router.on(HTTPMethod.POST, path, RequestHandler(hdler));
    return this;
  }

  @override
  PharaohRouter put(String path, RequestHandlerFunc hdler) {
    _router.on(HTTPMethod.PUT, path, RequestHandler(hdler));
    return this;
  }

  @override
  PharaohRouter trace(String path, RequestHandlerFunc hdler) {
    _router.on(HTTPMethod.TRACE, path, RequestHandler(hdler));
    return this;
  }

  @override
  PharaohRouter use(HandlerFunc mdw, [route]) {
    return this;
  }

  Future<HandlerResult> resolve(Request req, Response response) async {
    final result = await _router.lookup(req.method, req.path);
    return (canNext: true, reqRes: (req: req, res: response));
  }
}


// final handlers = _group.findHandlers(reqRes.req);
// if (handlers.isEmpty) {
//   return (
//     canNext: true,
//     reqRes: (req: reqRes.req, res: reqRes.res.notFound())
//   );
// }

// final handlerStream = Stream.fromIterable(handlers);

// ReqRes result = reqRes;
// bool canNext = false;

// await for (final handler in handlerStream) {
//   canNext = false;
//   final hdlerResult = await handler.execute(reqRes);
//   result = hdlerResult.reqRes;
//   canNext = hdlerResult.canNext;

//   final breakOut = result.res.ended || !canNext;
//   if (breakOut) break;
// }

// result = await _postHandlerJob(result);

// return (canNext: canNext, reqRes: result);

// Future<ReqRes> _postHandlerJob(ReqRes reqRes) async {
//   var req = reqRes.req, res = reqRes.res;

//   /// deal with sessions
//   final session = req.session;
//   if (session != null &&
//       (session.saveUninitialized || session.resave || session.modified)) {
//     await session.save();
//     res = res.withCookie(session.cookie!);
//   }

//   return (req: req, res: res);
// }