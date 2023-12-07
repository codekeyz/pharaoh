import 'package:pharaoh/pharaoh.dart';

import 'utils.dart';

typedef ParameterDescriptor<T> = T Function(dynamic value);

ParameterDescriptor<num> numDescriptor = (input) {
  input = input.toString();
  if (num.tryParse(input) == null) {
    throw PharaohValidationError('Invalid parameter value', input);
  }
  return num.parse(input);
};

ParameterDescriptor regexDescriptor = (input) {
  try {
    final regex = descriptorToRegex(input);
    if (regex.hasMatch(input.toString())) return input;
  } catch (_) {}

  throw PharaohValidationError('Invalid parameter value', input);
};
