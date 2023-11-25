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
  bool saveUninitialized = false,
  bool resave = true,

  /// The expiration is reset to the original maxAge,
  /// resetting the expiration countdown and forces
  /// the session identifier cookie to be set on every response.
  bool rolling = false,
  GenSessionIdFunc? genId,
  SessionStore? store,
  required CookieOpts cookie,
}) {
  final opts = cookie..validate();
  final sessionStore = store ??= InMemoryStore();
  final uuid = Uuid();

  return (req, res, next) async {
    void nextWithSession(Session session, {bool attachCookie = false}) async {
      if (attachCookie) res = res.withCookie(session.cookie!);
      req[RequestContext.session] = session;
      req[RequestContext.sessionId] = session.id;
      return next((req: req, res: res));
    }

    if (!req.path.startsWith(opts.path)) return next();
    if (req.session?.valid ?? false) return next();

    final req_sid =
        req.signedCookies.firstWhereOrNull((e) => e.name == name)?.value;

    if (req_sid != null) {
      final s_ = await sessionStore.get(req_sid);
      if (s_ != null && s_.valid) {
        if (rolling) {
          final rolled = bakeCookie(name, req_sid, opts);
          s_.cookie = rolled;
          await sessionStore.set(req_sid, s_);
        }

        return nextWithSession(s_, attachCookie: rolling);
      }

      await sessionStore.destroy(req_sid);
    }

    final sessionId = await genId?.call(req) ?? uuid.v4();
    final session = Session(sessionId, store: sessionStore);
    final cookie = bakeCookie(name, sessionId, opts);
    session.cookie = cookie;

    if (saveUninitialized) {
      await sessionStore.set(sessionId, session);
    }

    return nextWithSession(session, attachCookie: true);
  };
}
