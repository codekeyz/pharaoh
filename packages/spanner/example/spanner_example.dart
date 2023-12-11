import 'dart:convert';
import 'dart:io';

import 'package:spanner/spanner.dart';

typedef Handler = String Function(Map<String, dynamic> params);

void main() async {
  final spanner = Spanner();

  getUsers(Map<String, dynamic> params) => jsonEncode(['Foo', 'Bar']);

  getUser(Map<String, dynamic> params) => 'Hello ${params['userId']}';

  spanner
    ..addRoute(HTTPMethod.GET, '/', getUsers)
    ..addRoute(HTTPMethod.GET, '/<userId>', getUser);

  final server = await HttpServer.bind('localhost', 0);

  print('Server Started on port: ${server.port}');

  server.listen((request) {
    if (request.method != 'GET') {
      request.response
        ..write('Request not supported')
        ..close();
      return;
    }

    final result = spanner.lookup(HTTPMethod.GET, request.uri.path);
    if (result == null) {
      request.response
        ..write('Request not supported')
        ..close();
      return;
    }

    final params = result.params; // Map<String, dynamic>

    /// your handler will be in this list.
    ///
    /// If any middlewares where resolved along the route to this handler
    /// they'll be present in the list
    ///
    /// The list is ordered in the exact way you registed your middlewares
    /// and handlers
    final resolvedHandler = result.values; // List<dynamic>

    final handlerResult = (resolvedHandler.first as Handler).call(result.params);
    request.response
      ..write(handlerResult)
      ..close();
  });
}
