import 'dart:io';

import 'package:pharaoh/src/utils/utils.dart';

import '../http/cookie.dart';
import '../http/request.dart';
import '../router/router_handler.dart';

Middleware cookieParser({CookieOpts opts = const CookieOpts()}) {
  opts.validate();

  return (req, res, next) async {
    final rawcookies = req.req.cookies;
    if (rawcookies.isEmpty) return next();

    final unSignedCookies = rawcookies.where((e) => !e.signed).toList();
    var signedCookies = rawcookies.where((e) => e.signed).toList();

    final secret = opts.secret;
    if (secret != null && signedCookies.isNotEmpty) {
      final verifiedCookies = <Cookie>[];

      for (final cookie in signedCookies) {
        final realValue = unsignValue(cookie.actualStr, secret);
        if (realValue != null) verifiedCookies.add(cookie..value = realValue);
      }
      signedCookies = verifiedCookies;
    }

    req[RequestContext.cookies] = unSignedCookies;
    req[RequestContext.signedCookies] = signedCookies;

    next(req);
  };
}
