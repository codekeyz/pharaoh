import 'dart:async';

import '../http/request.dart';
import '../http/response.dart';
import '../utils/exceptions.dart';

typedef ReqRes = ({Request req, Response res});

typedef HandlerResult = ({bool canNext, ReqRes reqRes});

typedef ReqResHook = FutureOr<ReqRes> Function(ReqRes reqRes);

typedef NextFunction<Next> = dynamic Function([dynamic result, Next? chain]);

typedef RequestHandler = FutureOr<dynamic> Function(Request req, Response res);

typedef Middleware = FutureOr<void> Function(Request req, Response res, NextFunction next);

extension ReqResExtension on ReqRes {
  ReqRes merge(dynamic val) {
    if (val == null) return this;
    if (val is Request) return (req: val, res: this.res);
    if (val is Response) return (req: this.req, res: val);
    if (val is ReqRes) return val;
    throw PharaohException.value('Invalid Type used on merge', val);
  }
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

Middleware useRequestHandler(RequestHandler handler) => (req, res, next_) async {
      final result = await handler(req, res);
      next_(result);
    };

Future<HandlerResult> executeHandlers(Iterable<Middleware> handlers, final ReqRes reqRes) async {
  ReqRes result = reqRes;
  bool canGotoNext = false;
  final stack = List<Middleware>.from(handlers);

  while (stack.isNotEmpty) {
    final middleware = stack.removeAt(0);
    canGotoNext = false;

    await middleware.call(result.req, result.res, ([nr_, chain]) {
      result = result.merge(nr_);
      canGotoNext = true;
      if (result.res.ended) return;
      if (chain != null) stack.insert(0, chain);
    });

    if (result.res.ended) break;
  }

  return (canNext: canGotoNext, reqRes: result);
}
