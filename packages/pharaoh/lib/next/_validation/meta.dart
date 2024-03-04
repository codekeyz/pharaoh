// ignore_for_file: camel_case_types

import 'package:ez_validator/ez_validator.dart';

abstract class ClassPropertyValidator<T extends Object> {
  final String? name;

  /// TODO: we need to be able to infer nullability also from the type
  /// we'll need reflection for that, tho currently, the reason i'm not
  /// doing it is because of the amount of code the library (reflectable)
  /// generates just to enable this capability
  final bool optional;

  final T? defaultVal;

  Type get propertyType => T;

  const ClassPropertyValidator(
      {this.name, this.defaultVal, this.optional = false});

  EzValidator<T> get validator {
    final base = EzValidator<T>(defaultValue: defaultVal, optional: optional);
    return optional
        ? base.isType(propertyType)
        : base.required().isType(propertyType);
  }
}

class ezEmail extends ClassPropertyValidator<String> {
  final String? message;

  const ezEmail({super.name, super.defaultVal, super.optional, this.message});

  @override
  EzValidator<String> get validator => super.validator.email(message);
}

class ezDateTime extends ClassPropertyValidator<DateTime> {
  final String? message;

  final DateTime? minDate, maxDate;

  const ezDateTime(
      {super.name,
      super.defaultVal,
      super.optional,
      this.message,
      this.maxDate,
      this.minDate});

  @override
  EzValidator<DateTime> get validator {
    final base = super.validator.date(message);
    if (minDate != null) return base.minDate(minDate!);
    if (maxDate != null) return base.maxDate(maxDate!);
    return base;
  }
}

class ezMinLength extends ClassPropertyValidator<String> {
  final int value;

  const ezMinLength(this.value);

  @override
  EzValidator<String> get validator => super.validator.minLength(value);
}

class ezMaxLength extends ClassPropertyValidator<String> {
  final int value;

  const ezMaxLength(this.value);

  @override
  EzValidator<String> get validator => super.validator.maxLength(value);
}

class ezRequired<T extends Object> extends ClassPropertyValidator<T> {
  final Type? type;

  const ezRequired([this.type]);

  @override
  Type get propertyType => type ?? T;
}

class ezOptional extends ClassPropertyValidator {
  final Type type;
  final Object? defaultValue;

  const ezOptional(this.type, {this.defaultValue})
      : super(defaultVal: defaultValue);

  @override
  Type get propertyType => type;

  @override
  bool get optional => true;
}
