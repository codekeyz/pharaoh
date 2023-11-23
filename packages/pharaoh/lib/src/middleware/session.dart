import 'dart:async';

import '../http/session.dart';
import '../http/request.dart';
import '../router/handler.dart';

enum SessionUnset { keep, destroy }

abstract interface class SessionStore {
  FutureOr<List<dynamic>> get sessions;

  FutureOr<void> clear();

  FutureOr<void> destroy(String sessionId);

  FutureOr<void> set(String sessionId, Object? value);

  FutureOr<dynamic> get(String sessionId);

  FutureOr<void> touch(String sessionId, Object? session);
}

class SessionConfig {
  final FutureOr<String> Function(Request request)? generateId;
  final bool resaveSession;
  final bool saveUninitializedSession;
  final String secret;
  final SessionUnset unset;
  final SessionStore? store;
  final CookieOpts cookieOpts;

  const SessionConfig({
    required this.secret,
    this.generateId,
    this.store,
    this.resaveSession = true,
    this.saveUninitializedSession = true,
    this.unset = SessionUnset.destroy,
    this.cookieOpts = const CookieOpts(),
  });
}

HandlerFunc session(SessionConfig config) {
  final cookieOpts = config.cookieOpts;
  final sessionStore = config.store ?? InMemoryStore();

  return (req, res, next) async {
    final session = req.session;
    if (session != null) return next();

    final cookiePath = cookieOpts.path;
    if (cookiePath != req.path) return next();

    final sessionId = await config.generateId!.call(req);

    // final sessionId = config.generateId()
    // if (req.path != cookieOpts.path) return next();
  };
}
