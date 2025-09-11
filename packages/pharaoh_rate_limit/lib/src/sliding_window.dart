import 'rate_limiter.dart';

/// Sliding window rate limiter implementation
///
/// Tracks requests in a sliding time window and enforces limits
/// based on the number of requests within that window.
class SlidingWindowRateLimiter implements RateLimiter {
  final int _maxRequests;
  final Duration _windowSize;
  final Map<String, _SlidingWindow> _windows = {};

  SlidingWindowRateLimiter({
    required int maxRequests,
    required Duration windowSize,
  })  : _maxRequests = maxRequests,
        _windowSize = windowSize;

  @override
  bool allowRequest(String key) {
    final window = _getWindow(key);
    return window.allowRequest();
  }

  @override
  int getRemainingRequests(String key) {
    final window = _getWindow(key);
    return _maxRequests - window.requestCount;
  }

  @override
  DateTime? getResetTime(String key) {
    final window = _getWindow(key);
    return window.oldestRequest?.add(_windowSize);
  }

  @override
  void cleanup() {
    final now = DateTime.now();
    final cutoff = now.subtract(_windowSize.multiply(2));

    _windows.removeWhere((key, window) {
      window._cleanup();
      return window.requests.isEmpty || window.requests.first.isBefore(cutoff);
    });
  }

  _SlidingWindow _getWindow(String key) {
    final window = _windows[key];
    if (window == null) {
      return _windows[key] = _SlidingWindow(_maxRequests, _windowSize);
    }

    window._cleanup();
    return window;
  }
}

class _SlidingWindow {
  final int maxRequests;
  final Duration windowSize;
  final List<DateTime> requests = [];

  _SlidingWindow(this.maxRequests, this.windowSize);

  bool allowRequest() {
    _cleanup();

    if (requests.length < maxRequests) {
      requests.add(DateTime.now());
      return true;
    }

    return false;
  }

  int get requestCount => requests.length;

  DateTime? get oldestRequest => requests.isEmpty ? null : requests.first;

  void _cleanup() {
    final now = DateTime.now();
    final cutoff = now.subtract(windowSize);

    requests.removeWhere((timestamp) => timestamp.isBefore(cutoff));
  }
}

extension on Duration {
  Duration multiply(int factor) {
    return Duration(microseconds: inMicroseconds * factor);
  }
}
