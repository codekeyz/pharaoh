import 'dart:async';

import 'package:collection/collection.dart';
import 'package:pharaoh/src/http/request.dart';
import 'package:uuid/uuid.dart';

import '../http/cookie.dart';
import '../http/session.dart';
import '../router/handler.dart';

typedef GenSessionIdFunc = FutureOr<String> Function(Request request);

HandlerFunc session({
  String name = Session.name,
  GenSessionIdFunc? generateId,
  SessionStore? store,
  required CookieOpts cookieOpts,
}) {
  final opts = cookieOpts..validate();
  final sessionStore = store ??= InMemoryStore();
  final uuid = Uuid();

  return (req, res, next) async {
    void nextWithSession(Session session) {
      req[RequestContext.session] = session;
      req[RequestContext.sessionId] = session.id;
      return next((req: req, res: res));
    }

    if (!req.path.startsWith(opts.path)) return next();
    if (req.session?.valid ?? false) return next();

    final req_sid =
        req.signedCookies.firstWhereOrNull((e) => e.name == name)?.value;
    if (req_sid != null) {
      final session = await sessionStore.get(req_sid);
      if (session != null && session.valid) {
        return nextWithSession(session);
      }
      await sessionStore.destroy(req_sid);
    }

    final sessionId = await generateId?.call(req) ?? uuid.v4();
    final session =
        Session(sessionId, store: sessionStore, maxAge: cookieOpts.maxAge);
    await sessionStore.set(sessionId, session);

    /// add cookie to response and put session in context
    res = res.cookie(name, sessionId, opts);
    nextWithSession(session);
  };
}
