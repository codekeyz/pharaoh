import '../http/request.dart';

class PharoahException extends Error {
  /// Whether value was provided.
  final bool _hasValue;

  /// The invalid value.
  final dynamic invalidValue;

  /// Message describing the problem.
  final dynamic message;

  @pragma("vm:entry-point")
  PharoahException(this.message)
      : invalidValue = null,
        _hasValue = false;

  @pragma("vm:entry-point")
  PharoahException.value(this.message, [value])
      : invalidValue = value,
        _hasValue = true;

  String get _errorName => "Pharoah Error${!_hasValue ? "(s)" : ""}";

  @override
  String toString() {
    Object? message = this.message;
    var messageString = (message == null) ? "" : ": $message";
    String prefix = "$_errorName$messageString";
    if (!_hasValue) return prefix;
    // If we know the invalid value, we can try to describe the problem.
    String errorValue = Error.safeToString(invalidValue);
    return "$prefix ---> $errorValue";
  }
}

class PharoahErrorBody {
  final String path;
  final HTTPMethod method;
  final String message;

  const PharoahErrorBody(
    this.message,
    this.path, {
    required this.method,
  });

  Map<String, dynamic> get toJson => {
        "path": path,
        "method": method.name,
        "message": message,
      };
}
