import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:pharaoh/src/utils/utils.dart';

/// Sign the given [val] with [secret].
String sign(String val, String secret) {
  final hmac = Hmac(sha256, utf8.encode(secret));
  final bytes = utf8.encode(val);
  final digest = hmac.convert(bytes);
  return '$val.${base64.encode(digest.bytes).replaceAll(RegExp('=+\$'), '')}';
}

/// Unsign and decode the given [input] with [secret],
/// returning `null` if the signature is invalid.
String? unsign(String input, String secret) {
  var tentativeValue = input.substring(0, input.lastIndexOf('.'));
  var expectedInput = sign(tentativeValue, secret);
  final valid = safeCompare(expectedInput, input);
  return valid ? tentativeValue : null;
}
