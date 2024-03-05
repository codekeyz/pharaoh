import 'dart:collection';

import 'package:ez_validator/ez_validator.dart';
import 'package:pharaoh/next/_core/reflector.dart';
import 'package:pharaoh/pharaoh.dart';
import 'package:reflectable/reflectable.dart' as r;
import 'package:meta/meta.dart';

import '../_router/meta.dart';
import '../_router/utils.dart';
import 'meta.dart';

part 'dto_impl.dart';

const _instanceInvoke = r.InstanceInvokeCapability('^[^_]');

class DtoReflector extends r.Reflectable {
  const DtoReflector()
      : super(
            r.typeCapability,
            r.metadataCapability,
            r.newInstanceCapability,
            r.declarationsCapability,
            r.reflectedTypeCapability,
            _instanceInvoke,
            r.subtypeQuantifyCapability);
}

@protected
const dtoReflector = DtoReflector();

@dtoReflector
abstract class BaseDTO extends _BaseDTOImpl {
  @override
  noSuchMethod(Invocation invocation) {
    final property = symbolToString(invocation.memberName);
    return _databag[property];
  }
}
