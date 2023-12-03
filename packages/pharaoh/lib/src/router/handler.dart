import 'dart:async';

import '../http/request.dart';
import '../http/response.dart';
import '../utils/exceptions.dart';

typedef ReqRes = ({Request req, Response res});

typedef NextFunction<Next> = dynamic Function([dynamic result, Next? chain]);

typedef HandlerFunc = Function(Request req, Response res, NextFunction next);

typedef HandlerResult = ({bool canNext, ReqRes reqRes});

typedef ReqResHook = FutureOr<ReqRes> Function(ReqRes reqRes);

extension ReqResExtension on ReqRes {
  ReqRes merge(dynamic val) => switch (val.runtimeType) {
        Request => (req: val, res: this.res),
        Response => (req: this.req, res: val),
        ReqRes => val,
        Null => this,
        _ => throw PharaohException.value(
            'Next Function result can only be Request, Response or ReqRes', val)
      };
}

abstract interface class RouteHandler {
  final HandlerFunc _handler;

  RouteHandler._(this._handler);

  StreamController<HandlerFunc>? _streamCtrl;

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
    void newStream() =>
        _streamCtrl = StreamController<HandlerFunc>()..add(_handler);
    final ctrl = _streamCtrl;
    if (ctrl == null) return newStream();
    if (ctrl.hasListener && ctrl.isClosed) await ctrl.close();
    return newStream();
  }
}

typedef RequestHandlerFunc = FutureOr<dynamic> Function(
    $Request req, $Response res);

extension HandlerChainExtension on HandlerFunc {
  /// Chains the current middleware with a new one.
  HandlerFunc chain(HandlerFunc newChain) => (req, res, done) => this(
        req,
        res,
        ([nr, chain]) {
          // Use the existing chain if available, otherwise use the new chain
          HandlerFunc nextFunc = chain ?? newChain;

          // If there's an existing chain, recursively chain the new handler
          if (chain != null) {
            nextFunc = nextFunc.chain(newChain);
          }

          done(nr, nextFunc);
        },
      );
}

class RequestHandler extends RouteHandler {
  RequestHandler(final RequestHandlerFunc _func)
      : super._((req, res, next_) async {
          final result = await _func(req, res);
          next_(result);
        });
}

class Middleware extends RouteHandler {
  Middleware(final HandlerFunc _func) : super._(_func);
}
