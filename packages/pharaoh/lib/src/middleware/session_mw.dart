import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';

import '../http/cookie.dart';
import '../http/request.dart';
import '../router/router_handler.dart';
import '../utils/utils.dart';

part '../http/session.dart';

typedef GenSessionIdFunc = FutureOr<String> Function(Request request);

/// - [name] The name of the session ID cookie to set in the response
/// (and read from in the request).
/// The default value is `pharaoh.sid`.
///
/// - [saveUninitialized] Forces a session that is "uninitialized" to
/// be saved to the store. A session is uninitialized when it is new
/// but not modified.
/// Default value is `true`
///
/// - [rolling] The expiration is reset to the original maxAge,
/// resetting the expiration countdown and forces
/// the session identifier cookie to be set on every response.
///
/// - [resave] Forces the session to be saved back to the session store,
/// even if the session was never modified during the request.
/// Default value is `false`
///
/// - [genId] Function to call to generate a new session ID. Provide a
/// function that returns a string that will be used as a session ID.
/// Session ID is generated from [uuid]-[v4] by default.
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
Middleware session({
  String name = Session.name,
  String? secret,
  bool saveUninitialized = true,
  bool rolling = false,
  bool resave = false,
  GenSessionIdFunc? genId,
  SessionStore? store,
  CookieOpts cookie = const CookieOpts(httpOnly: true, secure: false),
}) {
  if (secret != null) cookie = cookie.copyWith(secret: secret);
  final opts = cookie.copyWith(signed: true)..validate();
  final sessionStore = store ??= InMemoryStore();
  final uuid = Uuid();

  return (req, res, next) async {
    void nextWithSession(Session session) async {
      req[RequestContext.sessionId] = session.id;
      req[RequestContext.session] = session.._withStore(sessionStore);
      return next((req: req, res: res));
    }

    if (!req.path.startsWith(opts.path)) return next();
    if (req.session?.valid ?? false) return next();

    final reqSid = req.signedCookies.firstWhereOrNull((e) => e.name == name)?.value;
    if (reqSid != null) {
      var result = await sessionStore.get(reqSid);
      if (result != null && result.valid) {
        if (rolling) result = result..resetMaxAge();
        return nextWithSession(result);
      }

      await sessionStore.destroy(reqSid);
    }

    final sessionId = await genId?.call(req) ?? uuid.v4();
    final session = Session(sessionId);
    final cookie = bakeCookie(name, sessionId, opts);
    session
      ..cookie = cookie
      .._withConfig(saveUninitialized: saveUninitialized, resave: resave);

    return nextWithSession(session);
  };
}

final ReqResHook sessionPreResponseHook = (ReqRes reqRes) async {
  var req = reqRes.req, res = reqRes.res;
  final session = req.session;
  if (session != null &&
      (session.saveUninitialized || session.resave || session.modified)) {
    await session.save();
    res = res.withCookie(session.cookie!);
  }

  return (req: req, res: res);
};
