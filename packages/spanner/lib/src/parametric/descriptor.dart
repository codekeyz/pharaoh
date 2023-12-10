import 'utils.dart';

typedef ParameterDescriptor<T> = T Function(dynamic value);

ParameterDescriptor<num> numDescriptor = (input) {
  input = input.toString();
  final value = num.tryParse(input);
  if (value != null) return value;
  throw ArgumentError.value(input, null, 'Invalid parameter value');
};

ParameterDescriptor regexDescriptor = (input) {
  try {
    final regex = descriptorToRegex(input);
    if (regex.hasMatch(input.toString())) return input;
  } catch (_) {}

  throw ArgumentError.value(input, null, 'Invalid parameter value');
};
