import 'package:collection/collection.dart';
import 'package:pharaoh/src/http/request.dart';
import 'package:uuid/uuid.dart';

import '../http/cookie.dart';
import '../http/session.dart';
import '../router/handler.dart';

HandlerFunc session(SessionConfig config) {
  final opts = config.cookieOpts..validate();
  final SessionStore store = config.store ?? InMemoryStore();
  final uuid = Uuid();

  return (req, res, next) async {
    if (!req.path.startsWith(opts.path)) return next();
    if (req.session?.valid ?? false) return next();

    final name = config.name ?? Session.name;
    var sessionId = req.cookies.firstWhereOrNull((e) => e.name == name)?.value;
    if (sessionId != null) {
      final session = await store.get(sessionId);
      if (session != null) {
        if (session.valid) {
          await store.set(sessionId, session.resetMaxAge());
          return next();
        }
        await store.destroy(sessionId);
      }
    }

    sessionId = await config.generateId?.call(req) ?? uuid.v4();
    final cookie = bakeCookie(name, sessionId, opts);
    final session = Session(sessionId, cookie, store: store);
    await store.set(sessionId, session);

    /// put sessionId in context and add cookie to response
    res = res.cookie(name, sessionId);
    req[RequestContext.session] = session;
    req[RequestContext.sessionId] = sessionId;

    next((req: req, res: res));
  };
}
