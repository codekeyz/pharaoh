part of '../validation.dart';

abstract class ClassPropertyValidator<T extends Object> {
  final String? name;

  /// TODO: we need to be able to infer nullability also from the type
  /// we'll need reflection for that, tho currently, the reason i'm not
  /// doing it is because of the amount of code the library (reflectable)
  /// generates just to enable this capability
  final bool optional;

  final T? defaultVal;

  Type get propertyType => T;

  const ClassPropertyValidator({
    this.name,
    this.defaultVal,
    this.optional = false,
  });

  EzValidator<T> get validator {
    final base = EzValidator<T>(defaultValue: defaultVal, optional: optional);
    return optional
        ? base.isType(propertyType)
        : base.required().isType(propertyType);
  }
}
