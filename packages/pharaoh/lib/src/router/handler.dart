import 'dart:async';

import '../http/request.dart';
import '../http/response.dart';
import '../utils/exceptions.dart';
import 'route.dart';

typedef ReqRes = ({Request req, Response res});

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

typedef NextFunction<Next> = dynamic Function([dynamic result, Next? chain]);

/// This type of handler allows you to use the full
/// [Request] and [Response] object
///
/// See here: [Middleware]
typedef HandlerFunc = Function(Request req, Response res, NextFunction next);

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

typedef HandlerResult = ({bool canNext, ReqRes reqRes});

/// All route handler types must extend this class.
///
/// See: [RequestHandler] and [Middleware] types
abstract class RouteHandler {
  Route get route;
  HandlerFunc get handler;

  Map<String, String> _routeParams = {};

  Map<String, String> get params => _routeParams;

  void setParams(Map<String, String> params) {
    _routeParams = params;
  }

  RouteHandler prefix(String prefix);

  StreamController<HandlerFunc> _streamCtrl = StreamController<HandlerFunc>();

  Future<HandlerResult> execute(final ReqRes reqRes) async {
    await _resetStream();

    final request = reqRes.req;
    if (_routeParams.isNotEmpty) {
      for (final param in params.entries) {
        request.setParams(param.key, param.value);
      }
    }

    ReqRes result = reqRes;
    bool canGotoNext = false;

    await for (final executor in _streamCtrl.stream) {
      canGotoNext = false;
      await executor.call(
        result.req,
        result.res,
        ([nr_, chain]) {
          result = result.merge(nr_);
          canGotoNext = true;

          if (chain == null) {
            _streamCtrl.close();
          } else {
            _streamCtrl.add(chain);
          }
        },
      );
    }

    return (canNext: canGotoNext, reqRes: result);
  }

  Future<void> _resetStream() async {
    if (_streamCtrl.hasListener && !_streamCtrl.isClosed) {
      await _streamCtrl.close();
    }
    _streamCtrl = StreamController<HandlerFunc>()..add(handler);
  }
}

typedef RequestHandlerFunc = FutureOr<dynamic> Function(
  $Request req,
  $Response res,
);

/// - [RequestHandler] calls `next` automatically,
///  hence the reason there's no next function. See [RequestHandlerFunc].
class RequestHandler extends RouteHandler {
  final RequestHandlerFunc _func;
  final Route _route;

  RequestHandler(this._func, this._route);

  @override
  RequestHandler prefix(String prefix) => RequestHandler(
        _func,
        route.withPrefix(prefix),
      );

  @override
  HandlerFunc get handler => (req, res, next_) async {
        final result = await _func(req, res);
        next_(result);
      };

  @override
  Route get route => _route;
}

/// With middlewares, you get a `req`, `res`, and `next` function.
/// you do your processing and then notify us to proceed when you call `next`.
class Middleware extends RouteHandler {
  final HandlerFunc _func;
  final Route _route;
  Middleware(this._func, this._route);

  @override
  Middleware prefix(String prefix) => Middleware(
        _func,
        route.withPrefix(prefix),
      );

  @override
  HandlerFunc get handler => (req, res, next_) => _func(req, res, next_);

  @override
  Route get route => _route;
}
