import 'dart:io';

import '../router/router_handler.dart';

final logRequestHook = RequestHook(
  onBefore: (req, res) async {
    req['startTime'] = DateTime.now();
    return (req: req, res: res);
  },
  onAfter: (req, res) async {
    final startTime = req['startTime'] as DateTime;
    final elapsedTime = DateTime.now().difference(startTime).inMilliseconds;

    final logLines = """
Request:          ${req.method.name} ${req.path}
Content-Type:     ${req.mimeType}
Status Code:      ${res.statusCode}
Elapsed Time:     ${"$elapsedTime ms"}
-------------------------------------------------------
""";
    stdout.writeln(logLines);

    return (req: req, res: res);
  },
);
