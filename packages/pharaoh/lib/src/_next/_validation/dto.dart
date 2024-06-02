part of '../validation.dart';

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

abstract interface class _BaseDTOImpl {
  late Map<String, dynamic> data;

  void make(Request request) {
    data = const {};
    final (result, errors) = schema.validateSync(request.body ?? {});
    if (errors.isNotEmpty) {
      throw RequestValidationError.errors(ValidationErrorLocation.body, errors);
    }
    data = Map<String, dynamic>.from(result);
  }

  EzSchema? _schemaCache;

  EzSchema get schema {
    if (_schemaCache != null) return _schemaCache!;

    final mirror = dtoReflector.reflectType(runtimeType) as r.ClassMirror;
    final properties = mirror.getters.where((e) => e.isAbstract);

    final entries = properties.map((prop) {
      final returnType = prop.reflectedReturnType;
      final meta =
          prop.metadata.whereType<ClassPropertyValidator>().firstOrNull ??
              ezRequired(returnType);

      if (meta.propertyType != returnType) {
        throw ArgumentError(
            'Type Mismatch between ${meta.runtimeType}(${meta.propertyType}) & $runtimeType class property ${prop.simpleName}->($returnType)');
      }

      return MapEntry(meta.name ?? prop.simpleName, meta.validator);
    });

    final entriesToMap = entries.fold<Map<String, EzValidator<dynamic>>>(
        {}, (prev, curr) => prev..[curr.key] = curr.value);
    return _schemaCache = EzSchema.shape(entriesToMap);
  }
}

@dtoReflector
abstract class BaseDTO extends _BaseDTOImpl {
  @override
  noSuchMethod(Invocation invocation) {
    final property = symbolToString(invocation.memberName);
    return data[property];
  }
}
