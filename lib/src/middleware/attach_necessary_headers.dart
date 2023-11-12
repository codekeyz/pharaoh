import 'dart:io';

import '../router/route.dart';
import '../router/handler.dart';

Middleware attachNecessaryHeaders({includeXpoweredBy = true}) => Middleware(
      (req, res) {
        res.updateHeaders(
          (headers) {
            if (includeXpoweredBy) headers['X-Powered-By'] = 'Pharoah';
            headers[HttpHeaders.dateHeader] = DateTime.now().toUtc();
            headers[HttpHeaders.contentLengthHeader] = res.contentLength;
          },
        );
        return (req, res);
      },
      Route.any(),
    );
