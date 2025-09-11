# Pharaoh Rate Limit

Rate limiting middleware for the Pharaoh web framework. Provides token bucket and sliding window algorithms to protect your APIs from abuse and ensure fair usage.

## Features

- **Multiple algorithms**: Token bucket and sliding window rate limiting
- **Flexible configuration**: Customizable limits, time windows, and key generation
- **Standard headers**: Supports both modern and legacy rate limit headers
- **Skip functionality**: Bypass rate limiting for specific requests
- **Per-client tracking**: Automatic IP-based or custom key generation
- **Production ready**: Comprehensive test coverage and error handling

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  pharaoh_rate_limit: ^1.0.0
```

## Quick Start

```dart
import 'package:pharaoh/pharaoh.dart';
import 'package:pharaoh_rate_limit/pharaoh_rate_limit.dart';

final app = Pharaoh();

void main() async {
  // Basic rate limiting: 100 requests per 15 minutes
  app.use(rateLimit(
    max: 100,
    windowMs: Duration(minutes: 15),
  ));

  app.get('/api/data', (req, res) {
    return res.json({'message': 'Hello World!'});
  });

  await app.listen(port: 3000);
}
```

## Configuration Options

### Basic Options

```dart
app.use(rateLimit(
  max: 100,                              // Maximum requests per window
  windowMs: Duration(minutes: 15),       // Time window
  message: 'Too many requests!',         // Custom error message
  statusCode: 429,                       // HTTP status code for rate limited requests
));
```

### Advanced Options

```dart
app.use(rateLimit(
  max: 50,
  windowMs: Duration(minutes: 1),
  
  // Custom key generation (default: IP address)
  keyGenerator: (req) => req.headers['user-id']?.toString() ?? req.ipAddr,
  
  // Skip rate limiting for certain requests
  skip: (req) => req.headers['x-api-key'] == 'admin-key',
  
  // Response headers
  standardHeaders: true,    // RateLimit-* headers (default: true)
  legacyHeaders: false,     // X-RateLimit-* headers (default: false)
  
  // Rate limiting algorithm
  algorithm: RateLimitAlgorithm.tokenBucket,  // or slidingWindow
));
```

## Algorithms

### Token Bucket (Default)

Tokens are added to a bucket at a fixed rate. Each request consumes a token. When the bucket is empty, requests are rate limited.

```dart
app.use(rateLimit(
  max: 10,
  windowMs: Duration(seconds: 60),
  algorithm: RateLimitAlgorithm.tokenBucket,
));
```

### Sliding Window

Tracks requests in a sliding time window. More memory intensive but provides smoother rate limiting.

```dart
app.use(rateLimit(
  max: 10,
  windowMs: Duration(seconds: 60),
  algorithm: RateLimitAlgorithm.slidingWindow,
));
```

## Response Headers

When rate limiting is active, the following headers are added to responses:

### Standard Headers (enabled by default)
- `RateLimit-Limit`: Request limit per window
- `RateLimit-Remaining`: Remaining requests in current window
- `RateLimit-Reset`: Unix timestamp when the window resets
- `Retry-After`: Seconds to wait before retrying (when rate limited)

### Legacy Headers (optional)
- `X-RateLimit-Limit`: Request limit per window
- `X-RateLimit-Remaining`: Remaining requests in current window
- `X-RateLimit-Reset`: Unix timestamp when the window resets

## Examples

### Per-Route Rate Limiting

```dart
// Global rate limiting
app.use(rateLimit(max: 1000, windowMs: Duration(hours: 1)));

// Stricter limits for auth endpoints
app.use('/auth', rateLimit(
  max: 5,
  windowMs: Duration(minutes: 15),
  message: 'Too many login attempts',
));

app.post('/auth/login', (req, res) {
  // Login logic
});
```

### User-Based Rate Limiting

```dart
app.use(rateLimit(
  max: 100,
  windowMs: Duration(hours: 1),
  keyGenerator: (req) {
    // Rate limit by user ID instead of IP
    final userId = req.auth?['userId'];
    return userId?.toString() ?? req.ipAddr;
  },
));
```

### Skip Rate Limiting

```dart
app.use(rateLimit(
  max: 50,
  windowMs: Duration(minutes: 1),
  skip: (req) {
    // Skip rate limiting for admin users
    return req.auth?['role'] == 'admin';
  },
));
```

## Testing

Run the test suite:

```bash
cd packages/pharaoh_rate_limit
dart test
```

## Contributing

Contributions are welcome! Please read the [contributing guidelines](../../CONTRIBUTING.md) before submitting PRs.

## License

This project is licensed under the MIT License - see the [LICENSE](../../LICENSE) file for details.
