import 'dart:async';
import 'dart:convert';

class Session {
  static const String name = 'pharaoh.sid';

  final String id;
  final DateTime? expiry;
  final int? originalMaxAge;

  final SessionStore _store;

  Map<String, dynamic>? _dataBag;

  Session(
    this.id, {
    Duration? maxAge,
    required SessionStore store,
  })  : _store = store,
        originalMaxAge = maxAge?.inSeconds,
        expiry = maxAge == null ? null : DateTime.now().add(maxAge);

  Map<String, dynamic> toJson() => {
        'id': id,
        'expiry': expiry?.toIso8601String(),
        'originalMaxAge': originalMaxAge,
        'databag': _dataBag,
      };

  void operator []=(String name, dynamic value) {
    _dataBag ??= {};
    _dataBag?[name] = value;
  }

  dynamic operator [](String key) => _dataBag?[key];

  @override
  String toString() => jsonEncode(toJson());

  FutureOr<void> save() => _store.set(id, this);

  FutureOr<void> destroy() => _store.destroy(id);

  bool get valid {
    final exp = expiry;
    if (exp == null) return true;
    return exp.isAfter(DateTime.now());
  }
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
