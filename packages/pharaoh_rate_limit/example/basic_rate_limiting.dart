import 'package:pharaoh/pharaoh.dart';
import 'package:pharaoh_rate_limit/pharaoh_rate_limit.dart';

final app = Pharaoh();

void main() async {
  // Basic rate limiting: 100 requests per 15 minutes
  app.use(rateLimit(
    max: 100,
    windowMs: Duration(minutes: 15),
    message: 'Too many requests from this IP, please try again later.',
  ));

  // API routes
  app.get('/api/users', (req, res) {
    return res.json([
      {'id': 1, 'name': 'John Doe'},
      {'id': 2, 'name': 'Jane Smith'},
    ]);
  });

  app.get('/api/posts', (req, res) {
    return res.json([
      {'id': 1, 'title': 'Hello World', 'author': 'John'},
      {'id': 2, 'title': 'Dart is Awesome', 'author': 'Jane'},
    ]);
  });

  // More restrictive rate limiting for auth endpoints
  final authLimiter = rateLimit(
    max: 5,
    windowMs: Duration(minutes: 15),
    message: 'Too many authentication attempts, please try again later.',
    statusCode: 429,
  );

  app.use(authLimiter);

  app.post('/auth/login', (req, res) {
    // Simulate login logic
    final body = req.body as Map<String, dynamic>?;
    final username = body?['username'];
    final password = body?['password'];

    if (username == 'admin' && password == 'secret') {
      return res.json({'token': 'fake-jwt-token', 'user': username});
    }

    return res.status(401).json({'error': 'Invalid credentials'});
  });

  await app.listen(port: 3000);
  print('Server running on http://localhost:3000');
  print('Try making multiple requests to see rate limiting in action!');
}
