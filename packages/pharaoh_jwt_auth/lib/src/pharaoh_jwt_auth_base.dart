import 'dart:async';
import 'dart:io';

import 'package:pharaoh/pharaoh.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class PharaohJwtConfig {
  final FutureOr<JWTKey> secret;
  final List<JWTAlgorithm> algorithms;
  final bool authRequired;

  const PharaohJwtConfig({
    required this.algorithms,
    required this.secret,
    this.authRequired = true,
  });
}

const _tokenMalformed = 'Format is Authorization: Bearer [token]';
const _tokenNotFound = 'No authorization token was found';

HandlerFunc jwtAuth(PharaohJwtConfig config) {
  if (config.algorithms.isEmpty) {
    throw PharaohException.value(
        'JWT Algorithm must be provided', config.algorithms);
  }

  return (req, res, next) async {
    void reject(String message) {
      final error = res.makeError(message: message).toJson;
      next(res.unauthorized(data: error));
    }

    final _ = req.headers[HttpHeaders.authorizationHeader];
    if (_ is! Iterable) {
      return !config.authRequired ? next() : reject(_tokenNotFound);
    }
    final tokenParts = _.first.toString().split(' ');
    if (tokenParts.first != 'Bearer') return reject(_tokenMalformed);
    final token = tokenParts.last;
    if (JWT.tryDecode(token) == null) return reject(_tokenMalformed);

    final key = await config.secret;
    try {
      final result = JWT.verify(token, key);
      req.auth = result.payload;
    } on JWTException catch (e) {
      return reject(e.message);
    } catch (error) {
      return reject(_tokenMalformed);
    }

    return next(req);
  };
}
