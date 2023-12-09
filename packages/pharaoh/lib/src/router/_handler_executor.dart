import 'dart:async';

import 'router_handler.dart';

typedef HandlerResult = ({bool canNext, ReqRes reqRes});

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
      await executor.call(result.req, result.res, ([nr_, chain]) {
        result = result.merge(nr_);
        canGotoNext = true;

        if (chain == null || result.res.ended) {
          streamCtrl.close();
        } else {
          streamCtrl.add(chain);
        }
      });
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
