import 'dart:io';

import '../router/route.dart';
import '../router/handler.dart';

InternalMiddleware attachNecessaryHeaders({includeXpoweredBy = true}) =>
    InternalMiddleware(
      (req, res, next) {
        res.updateHeaders(
          (headers) {
            if (includeXpoweredBy) headers['X-Powered-By'] = 'Pharoah';
            headers[HttpHeaders.dateHeader] = DateTime.now().toUtc();
            headers[HttpHeaders.contentLengthHeader] = res.contentLength;
          },
        );

        next();
      },
      Route.any(),
    );
