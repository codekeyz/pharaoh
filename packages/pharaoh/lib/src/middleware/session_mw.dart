import 'dart:async';

import 'package:collection/collection.dart';
import 'package:pharaoh/src/http/request.dart';
import 'package:uuid/uuid.dart';

import '../http/cookie.dart';
import '../http/session.dart';
import '../router/handler.dart';

typedef GenSessionIdFunc = FutureOr<String> Function(Request request);

/// - [name] The name of the session ID cookie to set in the response
/// (and read from in the request).
/// The default value is `pharaoh.sid`.
///
/// - [saveUninitialized] Forces a session that is "uninitialized" to
/// be saved to the store. A session is uninitialized when it is new
/// but not modified. Choosing false is useful for implementing login sessions,
///
/// - [rolling] The expiration is reset to the original maxAge,
/// resetting the expiration countdown and forces
/// the session identifier cookie to be set on every response.
///
/// - [genId] Function to call to generate a new session ID. Provide a
/// function that returns a string that will be used as a session ID.
/// The default value is [uuid]-[v4].
///
/// - [store] The session store instance, defaults to a new MemoryStore
/// instance.
///
/// - [cookie] Settings object for the session ID cookie. The default
/// value is `{ path: '/', httpOnly: true, secure: false, maxAge: null }`.
///
/// - [secret] This is the secret used to sign the session ID cookie.
/// You can also provide it in [cookie.secret] options. But [secret] will
/// will be used if both are set.
HandlerFunc session({
  String name = Session.name,
  String? secret,
  bool saveUninitialized = false,
  bool rolling = false,
  GenSessionIdFunc? genId,
  SessionStore? store,
  CookieOpts cookie = const CookieOpts(httpOnly: true, secure: false),
}) {
  if (secret != null) cookie = cookie.copyWith(secret: secret);
  final opts = cookie.copyWith(signed: true)..validate();
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
      final session = await sessionStore.get(req_sid);
      if (session != null) {
        if (session.valid) {
          if (rolling) {
            final rolled = bakeCookie(name, req_sid, opts);
            session.cookie = rolled;
            await sessionStore.set(req_sid, session);
          }
          return nextWithSession(session, attachCookie: rolling);
        }
        await sessionStore.destroy(req_sid);
      }
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
