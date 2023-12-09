import 'dart:async';

import '../http/request.dart';
import '../http/request_impl.dart';
import '../http/response.dart';
import '../http/response_impl.dart';
import '../utils/exceptions.dart';

typedef ReqRes = ({$Request req, $Response res});

typedef NextFunction<Next> = dynamic Function([dynamic result, Next? chain]);

typedef Middleware = Function($Request req, $Response res, NextFunction next);

typedef RequestHandler = FutureOr<dynamic> Function(Request req, Response res);

typedef HandlerResult = ({bool canNext, ReqRes reqRes});

typedef ReqResHook = FutureOr<ReqRes> Function(ReqRes reqRes);

extension ReqResExtension on ReqRes {
  ReqRes merge(dynamic val) => switch (val.runtimeType) {
        $Request => (req: val, res: this.res),
        $Response => (req: this.req, res: val),
        ReqRes => val,
        Null => this,
        _ => throw PharaohException.value('Invalid Type used on merge', val)
      };
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

Middleware useRequestHandler(RequestHandler handler) => (req, res, next_) async {
      final result = await handler(req, res);
      next_(result);
    };

final class Executor {
  final Middleware _handler;

  Executor(this._handler);

  StreamController<Middleware>? _streamCtrl;

  Future<HandlerResult> execute(final ReqRes reqRes) async {
    await _resetStream();
    final streamCtrl = _streamCtrl!;

    ReqRes result = reqRes;
    bool canGotoNext = false;

    await for (final executor in streamCtrl.stream) {
      canGotoNext = false;
      await executor.call(
        result.req,
        result.res,
        ([nr_, chain]) {
          result = result.merge(nr_);
          canGotoNext = true;

          if (chain == null || result.res.ended) {
            streamCtrl.close();
          } else {
            streamCtrl.add(chain);
          }
        },
      );
    }

    return (canNext: canGotoNext, reqRes: result);
  }

  Future<void> _resetStream() async {
    void newStream() => _streamCtrl = StreamController<Middleware>()..add(_handler);
    final ctrl = _streamCtrl;
    if (ctrl == null) return newStream();
    if (ctrl.hasListener && ctrl.isClosed) await ctrl.close();
    return newStream();
  }
}
