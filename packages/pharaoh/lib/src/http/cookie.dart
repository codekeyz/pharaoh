import 'dart:convert';
import 'dart:io';

import '../utils/exceptions.dart';
import '../utils/utils.dart';

/// [expires] The time at which the cookie expires.
///
/// By default the value of `httpOnly` will be set to `true`.
class CookieOpts {
  final String? domain;
  final String? secret;
  final DateTime? expires;
  final Duration? maxAge;
  final SameSite? sameSite;
  final String path;
  final bool secure;
  final bool signed;
  final bool httpOnly;

  const CookieOpts({
    this.domain,
    this.expires,
    this.maxAge,
    this.sameSite,
    this.secret,
    this.httpOnly = false,
    this.signed = false,
    this.secure = false,
    this.path = '/',
  });

  void validate() {
    if (signed && secret == null) {
      throw PharaohException.value(
          'CookieOpts("secret") required for signed cookies');
    }
  }
}

extension CookieExtension on Cookie {
  void setMaxAge(Duration? value) {
    if (value == null) {
      expires = null;
      maxAge = null;
      return;
    }

    expires = DateTime.now().add(value);
    maxAge = value.inSeconds;
  }
}

Cookie bakeCookie(String name, Object? value, CookieOpts opts) {
  opts.validate();
  if (value is! String) value = 'j:${jsonEncode(value)}';
  if (opts.signed) value = 's:${signValue(value, opts.secret!)}';

  return Cookie(name, Uri.encodeComponent(value))
    ..httpOnly = opts.httpOnly
    ..domain = opts.domain
    ..path = opts.path
    ..secure = opts.secure
    ..sameSite = opts.sameSite
    ..setMaxAge(opts.maxAge);
}
