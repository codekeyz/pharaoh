import 'package:pharaoh/src/server.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    final server = Pharaoh();

    setUp(() {
      // Additional setup goes here.
    });

    test('First Test', () {
      expect(server.url, '');
    });
  });
}
