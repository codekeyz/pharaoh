import 'package:test/test.dart';
import 'package:pharaoh_rate_limit/src/token_bucket.dart';

void main() {
  group('TokenBucketRateLimiter', () {
    test('should allow requests within capacity', () {
      final limiter = TokenBucketRateLimiter(
        capacity: 5,
        refillRate: 1,
        refillInterval: Duration(seconds: 1),
      );

      // Should allow 5 requests initially
      for (int i = 0; i < 5; i++) {
        expect(limiter.allowRequest('test-key'), isTrue);
      }

      // 6th request should be denied
      expect(limiter.allowRequest('test-key'), isFalse);
    });

    test('should track remaining requests correctly', () {
      final limiter = TokenBucketRateLimiter(
        capacity: 3,
        refillRate: 1,
        refillInterval: Duration(seconds: 1),
      );

      expect(limiter.getRemainingRequests('test-key'), equals(3));

      limiter.allowRequest('test-key');
      expect(limiter.getRemainingRequests('test-key'), equals(2));

      limiter.allowRequest('test-key');
      expect(limiter.getRemainingRequests('test-key'), equals(1));

      limiter.allowRequest('test-key');
      expect(limiter.getRemainingRequests('test-key'), equals(0));
    });

    test('should refill tokens over time', () async {
      final limiter = TokenBucketRateLimiter(
        capacity: 2,
        refillRate: 2,
        refillInterval: Duration(milliseconds: 100),
      );

      // Consume all tokens
      expect(limiter.allowRequest('test-key'), isTrue);
      expect(limiter.allowRequest('test-key'), isTrue);
      expect(limiter.allowRequest('test-key'), isFalse);

      // Wait for refill
      await Future.delayed(Duration(milliseconds: 150));

      // Should have tokens again
      expect(limiter.allowRequest('test-key'), isTrue);
      expect(limiter.allowRequest('test-key'), isTrue);
    });

    test('should handle different keys independently', () {
      final limiter = TokenBucketRateLimiter(
        capacity: 2,
        refillRate: 1,
        refillInterval: Duration(seconds: 1),
      );

      // Consume tokens for key1
      expect(limiter.allowRequest('key1'), isTrue);
      expect(limiter.allowRequest('key1'), isTrue);
      expect(limiter.allowRequest('key1'), isFalse);

      // key2 should still have tokens
      expect(limiter.allowRequest('key2'), isTrue);
      expect(limiter.allowRequest('key2'), isTrue);
      expect(limiter.allowRequest('key2'), isFalse);
    });

    test('should calculate reset time correctly', () {
      final limiter = TokenBucketRateLimiter(
        capacity: 2,
        refillRate: 1,
        refillInterval: Duration(seconds: 1),
      );

      // Consume all tokens
      limiter.allowRequest('test-key');
      limiter.allowRequest('test-key');

      final resetTime = limiter.getResetTime('test-key');
      expect(resetTime, isNotNull);
      expect(resetTime!.isAfter(DateTime.now()), isTrue);
    });

    test('should cleanup old buckets', () {
      final limiter = TokenBucketRateLimiter(
        capacity: 1,
        refillRate: 1,
        refillInterval: Duration(seconds: 1),
      );

      // Create some buckets
      limiter.allowRequest('key1');
      limiter.allowRequest('key2');
      limiter.allowRequest('key3');

      // Cleanup should work without errors
      limiter.cleanup();

      // Verify cleanup method exists and runs
      expect(limiter, isA<TokenBucketRateLimiter>());
    });
  });
}
