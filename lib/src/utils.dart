import 'dart:convert';
import 'dart:io';

void sendJsonResponse(HttpResponse response, Map<String, dynamic> data) {
  response.headers.contentType = ContentType.json;
  response.write(jsonEncode(data));
  response.close();
}

void sendServerError(
  HttpResponse response,
  String errorMessage, {
  int code = HttpStatus.internalServerError,
}) {
  response.statusCode = code;
  response.write('Internal Server Error: $errorMessage');
  response.close();
}
