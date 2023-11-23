import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'request.dart';

/// [expires] The time at which the cookie expires.
///
/// By default the value of `httpOnly` will be set to `true`.
class CookieOpts {
  final String? domain;
  final String? secret;
  final DateTime? expires;
  final Duration? maxAge;
  final SameSite? sameSite;
  final String path;
  final bool secure;
  final bool signed;
  final bool httpOnly;

  const CookieOpts({
    this.domain,
    this.expires,
    this.maxAge,
    this.sameSite,
    this.secret,
    this.httpOnly = false,
    this.signed = false,
    this.secure = false,
    this.path = '/',
  });
}

enum SessionUnset { keep, destroy }

extension CookieExtension on Cookie {
  void setMaxAge(Duration? value) {
    if (value == null) {
      expires = null;
      maxAge = null;
      return;
    }

    expires = DateTime.now().add(value);
    maxAge = value.inSeconds;
  }
}

class Session {
  late Cookie _cookie;

  final String id;
  final SessionStore _store;
  final int? originalMaxAge;

  Session(
    this.id,
    Cookie cookie, {
    required SessionStore store,
  })  : _store = store,
        _cookie = cookie,
        originalMaxAge = cookie.maxAge;

  Cookie get cookie => _cookie;

  set cookie(Cookie cookie) {
    _cookie = cookie;
  }

  @override
  String toString() => jsonEncode({'cookie': cookie});

  Session resetMaxAge() {
    final seconds = originalMaxAge;
    if (seconds == null)
      _cookie.setMaxAge(null);
    else
      _cookie.setMaxAge(Duration(seconds: seconds));
    return this;
  }

  FutureOr<void> save() => _store.set(id, this);

  FutureOr<void> destroy() => _store.destroy(id);
}

abstract interface class SessionStore {
  FutureOr<List<Session>> get sessions;

  FutureOr<void> clear();

  FutureOr<void> destroy(String sessionId);

  FutureOr<void> set(String sessionId, Session value);

  FutureOr<Session?> get(String sessionId);

  FutureOr<void> touch(String sessionId, Cookie session);
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

class InMemoryStore implements SessionStore {
  final Map<String, Session> _sessionsMap = {};

  InMemoryStore();

  @override
  void clear() => _sessionsMap.clear();

  @override
  void destroy(String sessionId) => _sessionsMap.remove(sessionId);

  @override
  List<Session> get sessions => _sessionsMap.values.toList();

  @override
  void set(String sessionId, Session value) {
    // final _InternalSession session = (
    //   session: Session(Cookie('name', '')),
    //   originalMaxAge: Duration(seconds: 3),
    // );
    // _sessionsMap[sessionId] = session;
  }

  @override
  Session? get(String sessionId) => _sessionsMap[sessionId];

  @override
  FutureOr<void> touch(String sessionId, Cookie cookie) {
    final currentSession = get(sessionId);
    if (currentSession != null) {
      currentSession.cookie = cookie;
      set(sessionId, currentSession);
    }
  }
}
