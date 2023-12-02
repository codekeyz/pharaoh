import 'dart:convert';
import 'dart:io';

import 'package:pharaoh/pharaoh.dart';

/// path to where the [serviceAccountKey.json] is stored on the disk
final publicDir = '${Directory.current.path}/public';

/// ensure the [object] returned is encodable
Map<String, Object?> ensureEncodable(Map<String, Object?> object) {
  final result = Map<String, Object?>.from(object);

  object.forEach((key, value) {
    if (value is DateTime) {
      result[key] = value.toUtc().toIso8601String();
    } else if (value is Map<String, Object?>) {
      result[key] = ensureEncodable(value);
    } else if (value is List<Map<String, Object?>>) {
      result[key] = value.map((e) => ensureEncodable(e)).toList();
    }
  });

  return result;
}

Map<String, dynamic> get envVariables {
  final content = File("$publicDir/env.json").readAsStringSync();
  return jsonDecode(content);
}

class ApiError extends PharaohException {
  ApiError(super.message, this.statusCode);
  int statusCode;
}
