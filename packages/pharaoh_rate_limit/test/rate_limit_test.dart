import 'package:test/test.dart';
import 'package:pharaoh_rate_limit/src/token_bucket.dart';
import 'package:pharaoh_rate_limit/src/sliding_window.dart';
import 'package:pharaoh_rate_limit/src/rate_limit_middleware.dart';

void main() {
  group('Rate Limiting', () {
    group('TokenBucketRateLimiter', () {
      test('should allow requests within capacity', () {
        final limiter = TokenBucketRateLimiter(
          capacity: 3,
          refillRate: 1,
          refillInterval: Duration(seconds: 1),
        );

        expect(limiter.allowRequest('test'), isTrue);
        expect(limiter.allowRequest('test'), isTrue);
        expect(limiter.allowRequest('test'), isTrue);
        expect(limiter.allowRequest('test'), isFalse);
      });

      test('should track remaining requests', () {
        final limiter = TokenBucketRateLimiter(
          capacity: 2,
          refillRate: 1,
          refillInterval: Duration(seconds: 1),
        );

        expect(limiter.getRemainingRequests('test'), equals(2));
        limiter.allowRequest('test');
        expect(limiter.getRemainingRequests('test'), equals(1));
      });
    });

    group('SlidingWindowRateLimiter', () {
      test('should allow requests within limit', () {
        final limiter = SlidingWindowRateLimiter(
          maxRequests: 2,
          windowSize: Duration(seconds: 1),
        );

        expect(limiter.allowRequest('test'), isTrue);
        expect(limiter.allowRequest('test'), isTrue);
        expect(limiter.allowRequest('test'), isFalse);
      });

      test('should track remaining requests', () {
        final limiter = SlidingWindowRateLimiter(
          maxRequests: 3,
          windowSize: Duration(seconds: 1),
        );

        expect(limiter.getRemainingRequests('test'), equals(3));
        limiter.allowRequest('test');
        expect(limiter.getRemainingRequests('test'), equals(2));
      });
    });

    group('RateLimitMiddleware', () {
      test('should create middleware with token bucket algorithm', () {
        final middleware = rateLimit(
          max: 10,
          windowMs: Duration(minutes: 1),
          algorithm: RateLimitAlgorithm.tokenBucket,
        );

        expect(middleware, isA<Function>());
      });

      test('should create middleware with sliding window algorithm', () {
        final middleware = rateLimit(
          max: 10,
          windowMs: Duration(minutes: 1),
          algorithm: RateLimitAlgorithm.slidingWindow,
        );

        expect(middleware, isA<Function>());
      });
    });
  });
}
