import 'package:pharaoh/pharaoh.dart';
import 'package:spanner/spanner.dart';
import 'package:spookie/spookie.dart';

import 'fixtures/handlers.dart';

void main() {
  test('should execute request', () async {
    final router = Spanner()
      ..on(HTTPMethod.ALL, '/*', fooBarMdlw)
      ..on(HTTPMethod.GET, '/users/home', okHdler)
      ..on(HTTPMethod.ALL, '/*', fooBarMdlw)
      ..printTree();

    final result = router.lookup(HTTPMethod.GET, '/users/home', debug: true);
    print(result?.handlers);
  });
}
