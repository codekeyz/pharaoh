import 'package:pharaoh/pharaoh.dart';
import 'package:spookie/spookie.dart';

void main() {
  group('session', () {
    group('InMemoryStore', () {
      late SessionStore store;
      final sessionId = 'some-session-id';
      late Session session;

      setUpAll(() {
        store = InMemoryStore();
        session = Session(sessionId);
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

      test('should have .modified :true if session data modified', () async {
        final session = Session('some-new-session');
        expect(session.modified, false);

        session['name'] = 'Chima';
        session['tag'] = '@codekeyz';
        session['dogs'] = 2;

        expect(session.modified, true);
      });
    });
  });
}
