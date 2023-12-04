import 'package:pharaoh/pharaoh.dart';

/// request handler with response -> ok
class TestRequestHandler extends RequestHandler {
  TestRequestHandler({String result = 'Ok'})
      : super((_, res) => res.ok(result));
}

/// middleware that puts {'foo': 'bar'} into [req] params
class TestMiddleware extends Middleware {
  TestMiddleware({
    Map<String, dynamic> data = const {'foo': 'bar'},
  }) : super((req, _, next) => next(req..params['foo'] = 'bar'));
}

final okHdler = TestRequestHandler();
final fooBarMdlw = TestMiddleware();
