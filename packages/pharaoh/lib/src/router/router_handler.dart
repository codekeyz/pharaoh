import 'dart:async';

import '../http/request.dart';
import '../http/response.dart';
import '../utils/exceptions.dart';

typedef ReqRes = ({Request req, Response res});

typedef NextFunction<Next> = dynamic Function([dynamic result, Next? chain]);

typedef Middleware = Function(Request req, Response res, NextFunction next);

typedef RequestHandler = FutureOr<dynamic> Function(Request req, Response res);

typedef ReqResHook = FutureOr<ReqRes> Function(ReqRes reqRes);

extension ReqResExtension on ReqRes {
  ReqRes merge(dynamic val) {
    if (val == null) return this;
    if (val is Request) return (req: val, res: this.res);
    if (val is Response) return (req: this.req, res: val);
    if (val is ReqRes) return val;
    throw PharaohException.value('Invalid Type used on merge', val);
  }
}

extension HandlerChainExtension on Middleware {
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
