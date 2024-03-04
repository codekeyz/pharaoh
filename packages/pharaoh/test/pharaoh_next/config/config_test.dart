import 'package:pharaoh/next/core.dart';
import 'package:pharaoh/next/http.dart';
import 'package:spookie/spookie.dart';

import '../core/core_test.dart';
import './config_test.reflectable.dart' as r;

Matcher throwsArgumentErrorWithMessage(String message) =>
    throwsA(isA<ArgumentError>().having((p0) => p0.message, '', message));

class AppServiceProvider extends ServiceProvider {}

void main() {
  setUpAll(() => r.initializeReflectable());

  group('App Config Test', () {
    test('should return AppConfig instance', () async {
      final testApp = TestKidsApp(
          middlewares: [TestMiddleware], providers: [AppServiceProvider]);
      expect(testApp, isNotNull);
    });

    test('should use prioritize `port` over port in `url`', () {
      const config = AppConfig(
        name: 'Foo Bar',
        environment: 'debug',
        isDebug: true,
        key: 'asdfajkl',
        url: 'http://localhost:3000',
        port: 4000,
      );

      expect(config.url, 'http://localhost:4000');
      expect(config.port, 4000);
    });
  });
}
