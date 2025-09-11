import 'dart:math';

import 'rate_limiter.dart';

/// Token bucket rate limiter implementation
///
/// Uses the token bucket algorithm where tokens are added to a bucket
/// at a fixed rate and requests consume tokens from the bucket.
class TokenBucketRateLimiter implements RateLimiter {
  final int _capacity;
  final int _refillRate;
  final Duration _refillInterval;
  final Map<String, _TokenBucket> _buckets = {};

  TokenBucketRateLimiter({
    required int capacity,
    required int refillRate,
    Duration refillInterval = const Duration(seconds: 1),
  })  : _capacity = capacity,
        _refillRate = refillRate,
        _refillInterval = refillInterval;

  @override
  bool allowRequest(String key) {
    final bucket = _getBucket(key);
    return bucket.consume();
  }

  @override
  int getRemainingRequests(String key) {
    final bucket = _getBucket(key);
    return bucket.tokens;
  }

  @override
  DateTime? getResetTime(String key) {
    final bucket = _getBucket(key);
    if (bucket.tokens >= _capacity) return null;

    final tokensNeeded = _capacity - bucket.tokens;
    final timeToRefill = Duration(
        milliseconds:
            (_refillInterval.inMilliseconds * tokensNeeded / _refillRate)
                .round());

    return bucket.lastRefill.add(timeToRefill);
  }

  @override
  void cleanup() {
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(hours: 1));

    _buckets.removeWhere((key, bucket) => bucket.lastRefill.isBefore(cutoff));
  }

  _TokenBucket _getBucket(String key) {
    final bucket = _buckets[key];
    if (bucket == null) {
      return _buckets[key] =
          _TokenBucket(_capacity, _refillRate, _refillInterval);
    }

    bucket._refill();
    return bucket;
  }
}

class _TokenBucket {
  final int capacity;
  final int refillRate;
  final Duration refillInterval;

  int tokens;
  DateTime lastRefill;

  _TokenBucket(this.capacity, this.refillRate, this.refillInterval)
      : tokens = capacity,
        lastRefill = DateTime.now();

  bool consume() {
    _refill();
    if (tokens > 0) {
      tokens--;
      return true;
    }
    return false;
  }

  void _refill() {
    final now = DateTime.now();
    final timeSinceLastRefill = now.difference(lastRefill);

    if (timeSinceLastRefill >= refillInterval) {
      final intervalsElapsed =
          timeSinceLastRefill.inMilliseconds / refillInterval.inMilliseconds;
      final tokensToAdd = (intervalsElapsed * refillRate).floor();

      tokens = min(capacity, tokens + tokensToAdd);
      lastRefill = now;
    }
  }
}
