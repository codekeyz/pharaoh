import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:pharaoh/pharaoh.dart';

typedef Authorizer = FutureOr<bool> Function(String username, String password);

typedef UnAuthorizedResponse = String Function($Request req);

typedef GetRealm = String Function(Request req);

HandlerFunc basicAuth({
  final Authorizer? authorizer,
  final UnAuthorizedResponse? unauthorizedResponse,
  final Map<String, String>? users,
  final bool challenge = false,
  final GetRealm? realm,
}) {
  return (req, res, next) async {
    void bounceRequest() {
      if (challenge) {
        String challengeString = 'Basic';
        var realmName = realm?.call(req);
        if (realmName != null) challengeString += ' realm="$realmName"';
        res.set(HttpHeaders.wwwAuthenticateHeader, challengeString);
      }
      final errorMsg = unauthorizedResponse?.call(req);
      next(res.unauthorized(data: errorMsg));
    }

    final authHeader = req.headers[HttpHeaders.authorizationHeader];
    if (authHeader == null || authHeader is! Iterable || authHeader.isEmpty) {
      return bounceRequest();
    }

    var authParts = (authHeader.last as String).split(' ');
    if (authParts[0].toLowerCase() != 'basic') return bounceRequest();
    authParts = String.fromCharCodes(base64.decode(authParts.last)).split(':');

    final username = authParts.first, userpass = authParts.last;
    final secret = users?[username];

    final a = authorizer != null && await authorizer.call(username, userpass);
    final b = secret != null && safeCompare(userpass, secret);
    if (a || b) {
      req.auth = {"user": username, "pass": userpass};
      return next(req);
    }

    bounceRequest();
  };
}
