import 'dart:async';
import 'dart:io';

import 'package:pharaoh/pharaoh.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

const _tokenMalformed = 'Format is Authorization: Bearer [token]';
const _tokenNotFound = 'No authorization token was found';

Middleware jwtAuth({required FutureOr<JWTKey> Function() secret}) {
  return (req, res, next) async {
    void reject(String message) {
      final error = res.makeError(message: message);
      next(res.unauthorized(data: error));
    }

    final _ = req.headers[HttpHeaders.authorizationHeader];
    if (_ is! Iterable) return reject(_tokenNotFound);
    final tokenParts = _.first.toString().split(' ');
    if (tokenParts.first != 'Bearer') return reject(_tokenMalformed);
    final token = tokenParts.last;
    if (JWT.tryDecode(token) == null) return reject(_tokenMalformed);

    final key = await Future.sync(secret);
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
