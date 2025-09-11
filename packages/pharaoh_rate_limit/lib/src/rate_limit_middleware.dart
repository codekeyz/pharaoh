import 'package:pharaoh/pharaoh.dart';
import 'package:meta/meta.dart';

import 'rate_limiter.dart';
import 'token_bucket.dart';
import 'sliding_window.dart';

/// Configuration options for rate limiting middleware
class RateLimitOptions {
  /// Maximum number of requests allowed
  final int max;

  /// Time window for rate limiting
  final Duration windowMs;

  /// Custom message when rate limit is exceeded
  final String? message;

  /// Custom status code when rate limit is exceeded (default: 429)
  final int statusCode;

  /// Function to generate a unique key for each client
  final String Function(Request req)? keyGenerator;

  /// Function to skip rate limiting for certain requests
  final bool Function(Request req)? skip;

  /// Headers to include in the response
  final bool standardHeaders;

  /// Legacy headers (X-RateLimit-*)
  final bool legacyHeaders;

  /// Rate limiting algorithm to use
  final RateLimitAlgorithm algorithm;

  const RateLimitOptions({
    required this.max,
    required this.windowMs,
    this.message,
    this.statusCode = 429,
    this.keyGenerator,
    this.skip,
    this.standardHeaders = true,
    this.legacyHeaders = false,
    this.algorithm = RateLimitAlgorithm.tokenBucket,
  });
}

/// Available rate limiting algorithms
enum RateLimitAlgorithm {
  tokenBucket,
  slidingWindow,
}

/// Rate limiting middleware for Pharaoh
///
/// Example usage:
/// ```dart
/// app.use(rateLimit(
///   max: 100,
///   windowMs: Duration(minutes: 15),
///   message: 'Too many requests, please try again later.',
/// ));
/// ```
Middleware rateLimit({
  required int max,
  required Duration windowMs,
  String? message,
  int statusCode = 429,
  String Function(Request req)? keyGenerator,
  bool Function(Request req)? skip,
  bool standardHeaders = true,
  bool legacyHeaders = false,
  RateLimitAlgorithm algorithm = RateLimitAlgorithm.tokenBucket,
}) {
  final options = RateLimitOptions(
    max: max,
    windowMs: windowMs,
    message: message,
    statusCode: statusCode,
    keyGenerator: keyGenerator,
    skip: skip,
    standardHeaders: standardHeaders,
    legacyHeaders: legacyHeaders,
    algorithm: algorithm,
  );

  return RateLimitMiddleware(options).middleware;
}

/// Internal rate limit middleware implementation
@visibleForTesting
class RateLimitMiddleware {
  final RateLimitOptions options;
  late final RateLimiter _limiter;

  RateLimitMiddleware(this.options) {
    _limiter = _createLimiter();
  }

  RateLimiter _createLimiter() {
    switch (options.algorithm) {
      case RateLimitAlgorithm.tokenBucket:
        return TokenBucketRateLimiter(
          capacity: options.max,
          refillRate: options.max,
          refillInterval: options.windowMs,
        );
      case RateLimitAlgorithm.slidingWindow:
        return SlidingWindowRateLimiter(
          maxRequests: options.max,
          windowSize: options.windowMs,
        );
    }
  }

  Middleware get middleware => (req, res, next) async {
        // Skip rate limiting if skip function returns true
        if (options.skip?.call(req) == true) {
          return next(req);
        }

        final key = _generateKey(req);
        final allowed = _limiter.allowRequest(key);

        // Add rate limit headers
        _addHeaders(res, key);

        if (!allowed) {
          final message =
              options.message ?? 'Too many requests, please try again later.';
          return next(res.status(options.statusCode).json({'error': message}));
        }

        return next(req);
      };

  String _generateKey(Request req) {
    if (options.keyGenerator != null) {
      return options.keyGenerator!(req);
    }

    // Default key generation based on IP address
    return req.ipAddr;
  }

  void _addHeaders(Response res, String key) {
    final remaining = _limiter.getRemainingRequests(key);
    final resetTime = _limiter.getResetTime(key);

    if (options.standardHeaders) {
      res.header('RateLimit-Limit', options.max.toString());
      res.header('RateLimit-Remaining', remaining.toString());
      if (resetTime != null) {
        res.header('RateLimit-Reset',
            (resetTime.millisecondsSinceEpoch ~/ 1000).toString());
      }
    }

    if (options.legacyHeaders) {
      res.header('X-RateLimit-Limit', options.max.toString());
      res.header('X-RateLimit-Remaining', remaining.toString());
      if (resetTime != null) {
        res.header('X-RateLimit-Reset',
            (resetTime.millisecondsSinceEpoch ~/ 1000).toString());
      }
    }

    // Add Retry-After header when rate limited
    if (remaining <= 0 && resetTime != null) {
      final retryAfter = resetTime.difference(DateTime.now()).inSeconds;
      if (retryAfter > 0) {
        res.header('Retry-After', retryAfter.toString());
      }
    }
  }
}
