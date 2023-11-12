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
  String get _errorExplanation => "";

  @override
  String toString() {
    Object? message = this.message;
    var messageString = (message == null) ? "" : ": $message";
    String prefix = "$_errorName$messageString";
    if (!_hasValue) return prefix;
    // If we know the invalid value, we can try to describe the problem.
    String explanation = _errorExplanation;
    String errorValue = Error.safeToString(invalidValue);
    return "$prefix$explanation ---> $errorValue";
  }
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
