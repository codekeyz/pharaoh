import 'package:pharaoh/src/http/cookie.dart';
import 'package:pharaoh/src/http/session.dart';
import 'package:spookie/spookie.dart';

void main() {
  group('session', () {
    group('InMemoryStore', () {
      late SessionStore store;
      final sessionId = 'some-session-id';
      late Session session;

      setUpAll(() {
        store = InMemoryStore();
        session = Session(sessionId, bakeCookie('name', 'chima', CookieOpts()),
            store: store);
      });

      test('should have empty sessions when initialized', () async {
        final sessions = await store.sessions;
        expect(sessions, isEmpty);
      });

      test('should store session value', () async {
        await store.set(sessionId, session);
        expect(store.sessions, hasLength(1));
        expect(store.sessions, [session]);
      });

      test('should return stored session', () async {
        var result = await store.get(sessionId);
        expect(result, session);

        result = await store.get('non-existent-sessionId');
        expect(result, isNull);
      });

      test('should destroy session', () async {
        await store.destroy(sessionId);
        final sessions = await store.sessions;
        expect(sessions, isEmpty);
      });

      test('should clear sessions', () async {
        await store.clear();
        final sessions = await store.sessions;
        expect(sessions, isEmpty);
      });
    });
  });
}
