import 'dart:io';

import 'package:pharaoh/pharaoh.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

final pharaoh = Pharaoh();

void main() async {
  final app = pharaoh.router;

  app.use(logRequests);

  /// Using shelf_cors_header with Pharoah
  app.use(useShelfMiddleware(corsHeaders()));

  app.get(
    '/:user/json',
    (req, res) => res.json({'name': "Chima Precious", 'age': 28}),
  );

  // app.get('/website', (req, res) async {
  //   final result = await serveStatic(toShelfRequest((req)));
  //   if (result.statusCode >= 200 && result.statusCode < 300) {
  //     result.copyTo(res);

  //     final mimeType = lookupMimeType(req.path);
  //     if (mimeType != null) {
  //       res.type(ContentType.parse(mimeType));
  //     } else {
  //       res.type(ContentType.html);
  //     }

  //     return res;
  //   }

  //   return res.notFound();
  // });

  app.get(
    '/redirect',
    (req, res) => res.redirect('http://google.com'),
  );

  app.group('/api/v1', (router) {
    router.get(
      '/version',
      (req, res) => res.type(ContentType.text).ok('1.0.0'),
    );

    router.get(
      '/ping',
      (req, res) => res.type(ContentType.text).ok('2.0.0'),
    );

    router.get(
      '/:user/boy',
      (req, res) => res.json({"name": "Chima Precious"}),
    );

    router.post(
      '/sign-in',
      (req, res) => res.json(req.body ?? {}),
    );
  });

  await pharaoh.listen();
}
