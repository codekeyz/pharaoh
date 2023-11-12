class PharoahException implements Exception {
  final String message;

  const PharoahException(this.message);

  @override
  String toString() => "Pharoah Exception\n$message";
}
