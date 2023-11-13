import 'package:pharaoh/pharaoh.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    final server = Pharaoh();

    setUp(() {
      // Additional setup goes here.
    });

    test('First Test', () {
      expect(server.uri, '');
    });
  });
}
