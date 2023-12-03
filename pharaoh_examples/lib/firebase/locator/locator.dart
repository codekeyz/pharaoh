import 'package:dart_firebase_admin/firestore.dart';
import 'package:dart_firebase_admin/auth.dart';

final locator = Locator.instance;

class Locator {
  Locator._();

  static Locator? _instance;

  static Locator get instance => _instance ??= Locator._();

  late Auth _auth;

  /// a getter to expose the firebase auth
  Auth get auth => _auth;

  late Firestore _store;

  /// a getter to expose the firebase firestore
  Firestore get store => _store;

  initAuth(Auth auth) {
    _auth = auth;
  }

  initStore(Firestore store) {
    _store = store;
  }
}
