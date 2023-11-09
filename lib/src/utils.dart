import 'dart:convert';

String encodeJson(dynamic data) {
  if (data == null) {
    return 'null';
  } else if (data is Map) {
    return jsonEncode(data);
  }
  return data;
}
