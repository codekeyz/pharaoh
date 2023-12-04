import 'dart:async';

import 'package:spanner/spanner.dart';

import '../http/request.dart';
import '../http/response.dart';
import '../middleware/session_mw.dart';
import 'router_contract.dart';
import 'router_handler.dart';
import 'router_mixin.dart';

class PharaohRouter extends RouterContract<PharaohRouter>
    with RouteDefinitionMixin {
  PharaohRouter(Spanner spanner) {
    useSpanner(spanner);
  }

  final List<ReqResHook> _preResponseHooks = [
    sessionPreResponseHook,
  ];

  Future<HandlerResult> resolve(Request req, Response res) async {
    ReqRes reqRes = (req: req, res: res);
    final _ = spanner.lookup(req.method, req.path);
    if (_ == null) {
      return (canNext: true, reqRes: reqRes);
    } else if (_.handlers.isEmpty) {
      return (canNext: true, reqRes: (req: req, res: res.notFound()));
    }

    _.params.forEach((key, value) => req.setParams(key, value));

    reqRes = (req: req, res: res);
    for (final hdler in _.handlers) {
      final result = await hdler.execute(reqRes);
      reqRes = result.reqRes;
      if (!result.canNext || reqRes.res.ended) break;
    }

    for (final job in _preResponseHooks) {
      reqRes = await Future.microtask(() => job(reqRes));
    }

    if (!reqRes.res.ended) {
      return (
        canNext: true,
        reqRes: reqRes.merge(res.notFound("Route not found: ${req.path}"))
      );
    }

    return (canNext: true, reqRes: reqRes);
  }
}
