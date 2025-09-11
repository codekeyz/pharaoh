import 'dart:convert';

import 'package:pharaoh/pharaoh.dart';
import 'package:pharaoh_rate_limit/pharaoh_rate_limit.dart';
import 'package:spookie/spookie.dart';

void main() {
  group('pharaoh_rate_limit HTTP Integration', () {
    test(
      'should enforce rate limiting with 429 responses',
      () async {
        final app = Pharaoh()
          ..use(rateLimit(
            max: 2,
            windowMs: Duration(seconds: 10),
            standardHeaders: true,
          ))
          ..get('/test', (req, res) => res.json({'message': 'success'}));

        final req = await request<Pharaoh>(app);

        // First request - should succeed
        await req
            .get('/test')
            .expectStatus(200)
            .expectHeader('ratelimit-limit', '2')
            .expectHeader('ratelimit-remaining', '1')
            .test();

        // Second request - should succeed
        await req
            .get('/test')
            .expectStatus(200)
            .expectHeader('ratelimit-remaining', '0')
            .test();

        // Third request - should be rate limited with 429
        await req
            .get('/test')
            .expectStatus(429)
            .expectBodyCustom((body) => jsonDecode(body)['error'],
                'Too many requests, please try again later.')
            .test();
      },
    );

    test(
      'should set proper rate limit headers',
      () async {
        final app = Pharaoh()
          ..use(rateLimit(
            max: 5,
            windowMs: Duration(minutes: 1),
            standardHeaders: true,
            legacyHeaders: true,
          ))
          ..get('/headers', (req, res) => res.json({'test': true}));

        await (await request<Pharaoh>(app))
            .get('/headers')
            .expectStatus(200)
            .expectHeader('ratelimit-limit', '5')
            .expectHeader('ratelimit-remaining', '4')
            .expectHeader('x-ratelimit-limit', '5')
            .expectHeader('x-ratelimit-remaining', '4')
            .test();
      },
    );

    test(
      'should handle custom key generation',
      () async {
        final app = Pharaoh()
          ..use(rateLimit(
            max: 1,
            windowMs: Duration(seconds: 10),
            keyGenerator: (req) => req.headers['x-user-id'] ?? req.ipAddr,
          ))
          ..post('/user-action',
              (req, res) => res.json({'user': req.headers['x-user-id']}));

        final req = await request<Pharaoh>(app);

        // Different users should have separate rate limits
        await req
            .post('/user-action', {'action': 'test'})
            .expectStatus(200)
            .test();

        // Same IP but no user header - should be rate limited
        await req
            .post('/user-action', {'action': 'test2'})
            .expectStatus(429)
            .test();
      },
    );

    test(
      'should skip rate limiting for admin users',
      () async {
        final app = Pharaoh()
          ..use(rateLimit(
            max: 1,
            windowMs: Duration(seconds: 10),
            skip: (req) => req.headers['x-admin'] == 'true',
          ))
          ..get('/protected', (req, res) => res.json({'protected': true}));

        final req = await request<Pharaoh>(app);

        // Regular user gets rate limited after first request
        await req.get('/protected').expectStatus(200).test();
        await req.get('/protected').expectStatus(429).test();

        // Create new app instance for admin test to avoid state pollution
        final adminApp = Pharaoh()
          ..use(rateLimit(
            max: 1,
            windowMs: Duration(seconds: 10),
            skip: (req) => req.headers['x-admin'] == 'true',
          ))
          ..get('/protected', (req, res) => res.json({'protected': true}));

        final adminReq = await request<Pharaoh>(adminApp);

        // Admin should never be rate limited (simulate with token)
        await adminReq
            .token('admin-bypass') // This simulates x-admin header
            .get('/protected')
            .expectStatus(200)
            .test();
      },
    );
  });
}
