class PharoahException implements Exception {
  final String message;

  const PharoahException(this.message);

  @override
  String toString() => "Pharoah Exception\n$message";
}

class PharoahErrorBody {
  final String path;
  final String message;
  final int statusCode;

  const PharoahErrorBody(this.message, this.path, this.statusCode);

  Map<String, dynamic> get data => {
        "path": path,
        "message": message,
        "status_code": statusCode,
      };
}
