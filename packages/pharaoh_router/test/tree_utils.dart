import 'package:pharaoh_router/src/tree_utils.dart';
import 'package:test/test.dart';

void main() {
  group('tree_utils', () {
    test('isParametric', () {
      expect(isParametric('/user/<username>', start: 6), true);
      expect(isParametric('<username>/user/'), true);
    });

    test('getParameter', () {
      expect(getParameter('/user/<username>', start: 6), 'username');
      expect(getParameter('<filename>/user/'), 'filename');
      expect(getParameter('/user/<age>/hello', start: 6), 'age');
    });
  });
}
