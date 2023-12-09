import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:pharaoh/pharaoh.dart';

typedef Authorizer = FutureOr<bool> Function(String username, String password);

typedef UnAuthorizedResponse = String Function(Request req);

typedef GetRealm = String Function(Request req);

/// - [authorizer] You can pass your own [Authorizer] function, to check the credentials however you want.
///
/// - [unauthorizedResponse] You can either pass a static response or a function that gets
/// passed the pharaoh request object and is expected to return an error message [String].
///
/// - [users] If you simply want to check basic auth against one or multiple static credentials,
/// you can pass those credentials in the users option:
///
/// - [challenge] Per default the middleware will not add a WWW-Authenticate challenge header to responses of unauthorized requests.
/// You can enable that by adding challenge: true to the options object. This will cause most browsers to show a popup to enter credentials
/// on unauthorized responses.
/// You can set the realm (the realm identifies the system to authenticate against and can be used by clients to save credentials) of the challenge
/// by passing a static string or a function that gets passed the request object and is expected to return the challenge
Middleware basicAuth({
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
        res.header(HttpHeaders.wwwAuthenticateHeader, challengeString);
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
