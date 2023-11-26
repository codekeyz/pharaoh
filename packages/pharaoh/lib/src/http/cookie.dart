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

  CookieOpts copyWith({
    String? domain,
    String? secret,
    DateTime? expires,
    Duration? maxAge,
    SameSite? sameSite,
    String? path,
    bool? secure,
    bool? signed,
    bool? httpOnly,
  }) {
    return CookieOpts(
      domain: domain ?? this.domain,
      secret: secret ?? this.secret,
      expires: expires ?? this.expires,
      maxAge: maxAge ?? this.maxAge,
      sameSite: sameSite ?? this.sameSite,
      path: path ?? this.path,
      secure: secure ?? this.secure,
      signed: signed ?? this.signed,
      httpOnly: httpOnly ?? this.httpOnly,
    );
  }

  void validate() {
    if (signed && secret == null) {
      throw PharaohException.value(
          'CookieOpts("secret") required for signed cookies');
    }
  }
}

extension CookieExtension on Cookie {
  void setMaxAge(Duration? duration) {
    if (duration == null) {
      expires = null;
      maxAge = null;
      return;
    }

    expires = DateTime.now().add(duration);
    maxAge = duration.inSeconds;
  }

  String get decodedValue => Uri.decodeComponent(value);

  String get actualStr {
    // s:foo-bar-baz --> foo-bar-bar
    if (signed) return decodedValue.substring(2);
    return decodedValue;
  }

  dynamic get actualObj {
    if (!actualStr.startsWith('j:')) return actualStr;
    return jsonDecode(actualStr);
  }

  bool get signed => decodedValue.startsWith('s:');
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
