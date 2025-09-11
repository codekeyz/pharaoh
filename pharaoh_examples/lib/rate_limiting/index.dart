import 'package:pharaoh/pharaoh.dart';
import 'package:pharaoh_rate_limit/pharaoh_rate_limit.dart';

final app = Pharaoh()..useRequestHook(logRequestHook);

void main() async {
  // Global rate limiting: 50 requests per minute
  app.use(rateLimit(
    max: 50,
    windowMs: Duration(minutes: 1),
    message: 'Too many requests, please slow down!',
    standardHeaders: true,
    legacyHeaders: true,
  ));

  // Public API with generous limits
  app.get('/api/public/status', (req, res) {
    return res.json({
      'status': 'ok',
      'timestamp': DateTime.now().toIso8601String(),
      'server': 'pharaoh-demo'
    });
  });

  // More restrictive rate limiting for sensitive operations
  final strictLimiter = rateLimit(
    max: 3,
    windowMs: Duration(minutes: 1),
    message: 'Rate limit exceeded for sensitive operations',
    keyGenerator: (req) {
      // Use user ID if available, otherwise fall back to IP
      final userId = req.headers['x-user-id'];
      return userId?.toString() ?? req.ipAddr;
    },
    skip: (req) {
      // Skip rate limiting for admin users
      return req.headers['x-user-role'] == 'admin';
    },
  );

  // Apply strict limiter globally (affects all routes after this point)
  app.use(strictLimiter);

  app.post('/api/sensitive/data', (req, res) {
    return res.json({
      'message': 'Sensitive operation completed',
      'data': {'processed': true}
    });
  });

  app.delete('/api/sensitive/cleanup', (req, res) {
    return res.json({'message': 'Cleanup completed'});
  });

  // Different algorithm example - sliding window for uploads
  final uploadLimiter = rateLimit(
    max: 10,
    windowMs: Duration(minutes: 5),
    algorithm: RateLimitAlgorithm.slidingWindow,
    message: 'Upload rate limit exceeded',
  );

  app.use(uploadLimiter);

  app.post('/api/uploads/file', (req, res) {
    return res.json({
      'message': 'File upload simulated',
      'filename': 'example.txt',
      'size': 1024
    });
  });

  await app.listen(port: 3000);
  print('Rate limiting demo server running on http://localhost:3000');
  print('\nTry these endpoints:');
  print('- GET  /api/public/status (50 req/min)');
  print('- POST /api/sensitive/data (3 req/min)');
  print('- POST /api/uploads/file (10 req/5min, sliding window)');
  print('\nAdd headers to test custom key generation:');
  print('- x-user-id: your-user-id');
  print('- x-user-role: admin (skips rate limiting)');
}
