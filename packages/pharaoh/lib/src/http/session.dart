part of '../middleware/session_mw.dart';

class Session {
  static const String name = 'pharaoh.sid';

  final String id;
  SessionStore? _store;
  Cookie? cookie;
  Map<String, dynamic> _dataBag = {};

  Session(this.id);

  Session _withStore(SessionStore store) {
    _store = store;
    return this;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'databag': _dataBag,
        'cookie': cookie?.toString(),
        'expiry': expiry?.toIso8601String(),
        'originalMaxAge': cookie?.maxAge,
      };

  void operator []=(String name, dynamic value) {
    _dataBag[name] = value;
  }

  dynamic operator [](String key) => _dataBag[key];

  @override
  String toString() => jsonEncode(toJson());

  FutureOr<void> save() => _store!.set(id, this);

  FutureOr<void> destroy() => _store!.destroy(id);

  FutureOr<void> resetMaxAge() async {
    final cookie_ = cookie;
    if (cookie_ == null || cookie_.maxAge == null) return;

    final expires = DateTime.now().add(Duration(seconds: cookie_.maxAge!));
    cookie = cookie_..expires = expires;
    return save();
  }

  bool get valid {
    final exp = expiry;
    if (exp == null) return true;
    return exp.isAfter(DateTime.now());
  }

  DateTime? get expiry => cookie?.expires;
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
