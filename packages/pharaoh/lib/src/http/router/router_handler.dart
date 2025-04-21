part of '../router.dart';

typedef ReqRes = ({Request req, Response res});

final class RequestHook {
  final FutureOr<ReqRes> Function(Request req, Response res)? onBefore;
  final FutureOr<ReqRes> Function(Request req, Response res)? onAfter;
  const RequestHook({this.onAfter, this.onBefore});
}

typedef NextFunction<Next> = dynamic Function([dynamic result, Next? chain]);

typedef RequestHandler = FutureOr<dynamic> Function(Request req, Response res);

typedef Middleware = FutureOr<void> Function(
  Request req,
  Response res,
  NextFunction next,
);

extension ReqResExtension on ReqRes {
  ReqRes merge(dynamic val) => switch (val) {
        ReqRes() => val,
        Response() => (req: this.req, res: val),
        Request() => (req: val, res: this.res),
        null => this,
        _ => throw PharaohException.value('Invalid Type used on merge', val)
      };
}

extension MiddlewareChainExtension on Middleware {
  /// Chains the current middleware with a new one.
  Middleware chain(Middleware mdw) => (req, res, done) => this(
        req,
        res,
        ([nr, chain]) {
          // Use the existing chain if available, otherwise use the new chain
          Middleware nextMdw = chain ?? mdw;

          // If there's an existing chain, recursively chain the new handler
          if (chain != null) {
            nextMdw = nextMdw.chain(mdw);
          }

          done(nr, nextMdw);
        },
      );
}

Middleware useRequestHandler(RequestHandler handler) =>
    (req, res, next_) async {
      final result = await handler(req, res);
      next_(result);
    };

Future<ReqRes> executeHandlers(
  Iterable<dynamic> handlers,
  ReqRes reqRes,
) async {
  var result = reqRes;
  final iterator = handlers.iterator;

  Future<void> handleChain([dynamic nr_, Middleware? mdw]) async {
    result = result.merge(nr_);
    if (mdw == null || result.res.ended) return;

    return await mdw.call(
      result.req,
      result.res,
      ([nr_, chain]) => handleChain(nr_, chain),
    );
  }

  while (iterator.moveNext()) {
    await handleChain(null, iterator.current);
    if (result.res.ended) break;
  }

  return result;
}
