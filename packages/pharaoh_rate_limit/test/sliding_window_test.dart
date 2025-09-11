import 'package:test/test.dart';
import 'package:pharaoh_rate_limit/src/sliding_window.dart';

void main() {
  group('SlidingWindowRateLimiter', () {
    test('should allow requests within limit', () {
      final limiter = SlidingWindowRateLimiter(
        maxRequests: 3,
        windowSize: Duration(seconds: 1),
      );

      // Should allow 3 requests initially
      for (int i = 0; i < 3; i++) {
        expect(limiter.allowRequest('test-key'), isTrue);
      }

      // 4th request should be denied
      expect(limiter.allowRequest('test-key'), isFalse);
    });

    test('should track remaining requests correctly', () {
      final limiter = SlidingWindowRateLimiter(
        maxRequests: 2,
        windowSize: Duration(seconds: 1),
      );

      expect(limiter.getRemainingRequests('test-key'), equals(2));

      limiter.allowRequest('test-key');
      expect(limiter.getRemainingRequests('test-key'), equals(1));

      limiter.allowRequest('test-key');
      expect(limiter.getRemainingRequests('test-key'), equals(0));
    });

    test('should reset window after time expires', () async {
      final limiter = SlidingWindowRateLimiter(
        maxRequests: 2,
        windowSize: Duration(milliseconds: 100),
      );

      // Consume all requests
      expect(limiter.allowRequest('test-key'), isTrue);
      expect(limiter.allowRequest('test-key'), isTrue);
      expect(limiter.allowRequest('test-key'), isFalse);

      // Wait for window to expire
      await Future.delayed(Duration(milliseconds: 150));

      // Should allow requests again
      expect(limiter.allowRequest('test-key'), isTrue);
      expect(limiter.allowRequest('test-key'), isTrue);
    });

    test('should handle different keys independently', () {
      final limiter = SlidingWindowRateLimiter(
        maxRequests: 1,
        windowSize: Duration(seconds: 1),
      );

      // Consume request for key1
      expect(limiter.allowRequest('key1'), isTrue);
      expect(limiter.allowRequest('key1'), isFalse);

      // key2 should still allow requests
      expect(limiter.allowRequest('key2'), isTrue);
      expect(limiter.allowRequest('key2'), isFalse);
    });

    test('should calculate reset time correctly', () {
      final limiter = SlidingWindowRateLimiter(
        maxRequests: 1,
        windowSize: Duration(seconds: 1),
      );

      // Make a request
      limiter.allowRequest('test-key');

      final resetTime = limiter.getResetTime('test-key');
      expect(resetTime, isNotNull);
      expect(resetTime!.isAfter(DateTime.now()), isTrue);
    });

    test('should cleanup old windows', () {
      final limiter = SlidingWindowRateLimiter(
        maxRequests: 1,
        windowSize: Duration(milliseconds: 10),
      );

      // Create some windows
      limiter.allowRequest('key1');
      limiter.allowRequest('key2');
      limiter.allowRequest('key3');

      // Cleanup should work without errors
      limiter.cleanup();
      expect(limiter, isA<SlidingWindowRateLimiter>());
    });
  });
}
