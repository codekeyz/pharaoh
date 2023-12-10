import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';

String contentTypeToString(ContentType type, {String charset = 'utf-8'}) {
  return '${type.value}; charset=${type.charset ?? charset}';
}

/// Run [callback] and capture any errors that would otherwise be top-leveled.
///
/// If `this` is called in a non-root error zone, it will just run [callback]
/// and return the result. Otherwise, it will capture any errors using
/// [runZoned] and pass them to [onError].
void catchTopLevelErrors(
    void Function() callback, void Function(dynamic error, StackTrace) onError) {
  if (Zone.current.inSameErrorZone(Zone.root)) {
    return runZonedGuarded(callback, onError);
  } else {
    return callback();
  }
}

bool safeCompare(String a, String b) {
  if (a.length != b.length) return false;
  var result = 0;
  for (var i = 0; i < a.length; i++) {
    result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return result == 0;
}

/// Sign the given [value] with [secret].
String signValue(String value, String secret) {
  final hmac = Hmac(sha256, utf8.encode(secret));
  final bytes = utf8.encode(value);
  final digest = hmac.convert(bytes);
  return '$value.${base64.encode(digest.bytes).replaceAll(RegExp('=+\$'), '')}';
}

/// Unsign and decode the given [input] with [secret],
/// returning `null` if the signature is invalid.
String? unsignValue(String input, String secret) {
  var tentativeValue = input.substring(0, input.lastIndexOf('.'));
  var expectedInput = signValue(tentativeValue, secret);
  final valid = safeCompare(expectedInput, input);
  return valid ? tentativeValue : null;
}

String hashData(dynamic sess) {
  if (sess is! String) sess = jsonEncode(sess);
  return sha1.convert(utf8.encode(sess)).toString();
}
