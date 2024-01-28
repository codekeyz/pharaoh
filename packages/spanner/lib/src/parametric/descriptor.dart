import 'utils.dart';

typedef ParameterDescriptor<T> = T Function(dynamic value);

class SpannerRouteValidatorError extends ArgumentError {
  SpannerRouteValidatorError(dynamic value,
      {String message = 'Invalid parameter value'})
      : super.value(value, null, message);
}

ParameterDescriptor<num> numDescriptor = (input) {
  input = input.toString();
  final value = num.tryParse(input);
  if (value != null) return value;
  throw SpannerRouteValidatorError(input);
};

ParameterDescriptor regexDescriptor = (input) {
  try {
    final regex = descriptorToRegex(input);
    if (regex.hasMatch(input.toString())) return input;
  } catch (_) {}

  throw SpannerRouteValidatorError(input);
};
