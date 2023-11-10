import 'dart:convert';
import 'dart:io';

import 'router/router.dart';

HTTPMethod getHttpMethod(HttpRequest req) {
  switch (req.method) {
    case 'GET' || 'HEAD':
      return HTTPMethod.GET;
    case 'POST':
      return HTTPMethod.POST;
    case 'PUT':
      return HTTPMethod.PUT;
    case 'DELETE':
      return HTTPMethod.DELETE;
    default:
      throw Exception('Method ${req.method} not yet supported');
  }
}

String encodeJson(dynamic data) {
  if (data == null) {
    return 'null';
  } else if (data is Map) {
    return jsonEncode(data);
  }
  return data;
}
