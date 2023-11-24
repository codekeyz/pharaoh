import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'cookie.dart';
import 'request.dart';

enum SessionUnset { keep, destroy }

class Session {
  static const String name = 'connect.sid';

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

  set cookie(Cookie cookie) => _cookie = cookie;

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

  bool get valid {
    final expiry = cookie.expires;
    if (expiry == null) return true;
    return expiry.isAfter(DateTime.now());
  }
}

class SessionConfig {
  final String? name;
  final FutureOr<String> Function(Request request)? generateId;
  final String secret;
  final SessionUnset unset;
  final SessionStore? store;
  final CookieOpts cookieOpts;

  const SessionConfig({
    required this.secret,
    this.generateId,
    this.name,
    this.store,
    this.unset = SessionUnset.destroy,
    this.cookieOpts = const CookieOpts(),
  });
}

abstract interface class SessionStore {
  FutureOr<List<Session>> get sessions;

  FutureOr<void> clear();

  FutureOr<void> destroy(String sessionId);

  FutureOr<void> set(String sessionId, Session value);

  FutureOr<Session?> get(String sessionId);
}

class InMemoryStore extends SessionStore {
  final Map<String, Session> _sessionsMap = {};

  @override
  void clear() => _sessionsMap.clear();

  @override
  void destroy(String sessionId) => _sessionsMap.remove(sessionId);

  @override
  List<Session> get sessions => _sessionsMap.values.toList();

  @override
  void set(String sessionId, Session value) => _sessionsMap[sessionId] = value;

  @override
  Session? get(String sessionId) => _sessionsMap[sessionId];
}
