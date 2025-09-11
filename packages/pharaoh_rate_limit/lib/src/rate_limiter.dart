/// Abstract base class for rate limiting algorithms
abstract class RateLimiter {
  /// Check if a request should be allowed
  /// Returns true if allowed, false if rate limited
  bool allowRequest(String key);

  /// Get remaining requests for the given key
  int getRemainingRequests(String key);

  /// Get reset time for the given key
  DateTime? getResetTime(String key);

  /// Clean up expired entries
  void cleanup();
}
