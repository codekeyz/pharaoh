import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:pharaoh/src/utils/utils.dart';

/// Sign the given [val] with [secret].
String sign(String val, String secret) {
  final hmac = Hmac(sha256, utf8.encode(secret));
  final bytes = utf8.encode(val);
  final digest = hmac.convert(bytes);
  return '$val.${base64Url.encode(digest.bytes)}';
}

/// Unsign and decode the given [input] with [secret],
/// returning `null` if the signature is invalid.
String? unsign(String input, String secret) {
  var tentativeValue = input.substring(0, input.lastIndexOf('.'));
  var expectedInput = sign(tentativeValue, secret);
  final valid = safeCompare(expectedInput, input);
  return valid ? tentativeValue : null;
}

/*
  This portion of the code is based on the work of Denis Bakhtin.
  Original code can be found at https://github.com/denisbakhtin/shelf-secure-cookie/blob/ed5ba8eb049ce1e755272f53cac23061261b8fbd/lib/src/cookie_parser.dart#L169

  Parse a Cookie header value according to the rules in RFC 6265.
  This function was adapted from `dart:io`.
*/
List<Cookie> parseCookieString(String s) {
  var cookies = <Cookie>[];

  int index = 0;

  bool done() => index == -1 || index == s.length;

  void skipWS() {
    while (!done()) {
      if (s[index] != " " && s[index] != "\t") return;
      index++;
    }
  }

  String parseName() {
    int start = index;
    while (!done()) {
      if (s[index] == " " || s[index] == "\t" || s[index] == "=") break;
      index++;
    }
    return s.substring(start, index);
  }

  String parseValue() {
    int start = index;
    while (!done()) {
      if (s[index] == " " || s[index] == "\t" || s[index] == ";") break;
      index++;
    }
    return s.substring(start, index);
  }

  bool expect(String expected) {
    if (done()) return false;
    if (s[index] != expected) return false;
    index++;
    return true;
  }

  while (!done()) {
    skipWS();
    if (done()) continue;
    String name = parseName();
    skipWS();
    if (!expect("=")) {
      index = s.indexOf(';', index);
      continue;
    }
    skipWS();
    String value = parseValue();
    try {
      cookies.add(Cookie(name, value));
    } catch (_) {
      // Skip it, invalid cookie data.
    }
    skipWS();
    if (done()) continue;
    if (!expect(";")) {
      index = s.indexOf(';', index);
      continue;
    }
  }

  return cookies;
}
