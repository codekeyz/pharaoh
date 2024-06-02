// ignore_for_file: camel_case_types

import 'package:collection/collection.dart';
import 'package:ez_validator_dart/ez_validator.dart';
import 'package:meta/meta.dart';
import 'package:pharaoh/src/_next/core.dart';
import 'package:reflectable/reflectable.dart' as r;

import '../http/request.dart';
import 'router.dart';

part '_validation/dto.dart';
part '_validation/meta.dart';

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
