import '../http/cookie.dart';
import '../http/request.dart';
import '../router/handler.dart';
import '../utils/utils.dart';

HandlerFunc cookieParser({CookieOpts opts = const CookieOpts()}) {
  opts.validate();

  return (req, res, next) async {
    final rawCookies = req.req.cookies;
    var parsedCookies = req.cookies;
    if (rawCookies.isEmpty || parsedCookies.isNotEmpty) return next();

    final secret = opts.secret;
    if (secret != null) {
      parsedCookies = rawCookies.map((e) {
        final val = unsignValue(e.value, secret);
        return val == null ? e : (e..value = val);
      }).toList();
    }

    next(req..[RequestContext.cookies] = parsedCookies);
  };
}
