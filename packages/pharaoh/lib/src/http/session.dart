part of '../middleware/session_mw.dart';

class Session {
  static const String name = 'pharaoh.sid';

  final String id;
  late final Map<String, dynamic> _dataBag;
  late final String hash;

  bool _resave = false;
  bool _saveUninitialized = false;

  bool get resave => _resave;
  bool get saveUninitialized => _saveUninitialized;

  SessionStore? _store;
  Cookie? cookie;

  Session(
    this.id, {
    Map<String, dynamic> data = const {},
  }) : _dataBag = {...data} {
    hash = hashData(_dataBag);
  }

  void _withStore(SessionStore store) {
    _store = store;
  }

  void _withConfig({bool? resave, bool? saveUninitialized}) {
    this._resave = resave ?? false;
    this._saveUninitialized = saveUninitialized ?? false;
  }

  void resetMaxAge() {
    final cookie_ = cookie;
    if (cookie_ == null || cookie_.maxAge == null) return;
    final expires = DateTime.now().add(Duration(seconds: cookie_.maxAge!));
    cookie = cookie_..expires = expires;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'data': _dataBag,
        'cookie': cookie?.toString(),
      };

  void operator []=(String name, dynamic value) {
    _dataBag[name] = value;
  }

  dynamic operator [](String key) => _dataBag[key];

  @override
  String toString() => jsonEncode(toJson());

  FutureOr<void> save() => _store!.set(id, this);

  FutureOr<void> destroy() => _store!.destroy(id);

  bool get valid {
    final exp = expiry;
    if (exp == null) return true;
    return exp.isAfter(DateTime.now());
  }

  bool get modified => hash != hashData(_dataBag);

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
