import '../tree/node.dart';
import '../tree/tree.dart';
import 'descriptor.dart';
import 'utils.dart';

final _knownDescriptors = {'number': numDescriptor};

SingleParameterDefn _singleParamDefn(RegExpMatch m) {
  final group = m.group(2)!;
  var param = group;

  Iterable<ParameterDescriptor>? descriptors;

  if (group.contains('|')) {
    final parts = m.group(2)!.split('|');
    param = parts.first;

    if (parts.length > 1) {
      descriptors = parts.sublist(1).map((e) {
        final value = e.isRegex ? regexDescriptor : _knownDescriptors[e];
        if (value == null) {
          throw ArgumentError.value(
              e, null, 'Parameter definition has invalid descriptor');
        }
        return value;
      });
    }
  }

  return SingleParameterDefn._(
    param,
    prefix: m.group(1)?.nullIfEmpty,
    suffix: m.group(3)?.nullIfEmpty,
    descriptors: descriptors ?? const [],
  );
}

ParameterDefinition buildParamDefinition(String part) {
  if (closeDoorParametricRegex.hasMatch(part)) {
    throw ArgumentError.value(
        part, null, 'Parameter definition is invalid. Close door neighbors');
  }

  final matches = parametricDefnsRegex.allMatches(part);
  if (matches.isEmpty) {
    throw ArgumentError.value(part, null, 'Parameter definition is invalid');
  }

  if (matches.length == 1) {
    return _singleParamDefn(matches.first);
  }

  final parts = matches.map(_singleParamDefn).toList(growable: false);
  return CompositeParameterDefinition._(parts);
}

abstract class ParameterDefinition implements HandlerStore {
  String get name;

  String get templateStr;

  RegExp get template;

  String get key;

  bool get terminal;

  Iterable<ParamAndValue> resolveParams(String pattern);
}

class SingleParameterDefn extends ParameterDefinition with HandlerStoreMixin {
  @override
  final String name;

  final String? prefix;
  final String? suffix;

  final Iterable<ParameterDescriptor> descriptors;

  @override
  final String templateStr;

  @override
  late final RegExp template;

  @override
  String get key => 'prefix=$prefix&suffix=$suffix&terminal=$terminal';

  bool _terminal;

  @override
  bool get terminal => _terminal;

  SingleParameterDefn._(
    this.name, {
    this.descriptors = const [],
    this.prefix,
    this.suffix,
  })  : templateStr = buildTemplateString(
          name: name,
          prefix: prefix,
          suffix: suffix,
        ),
        _terminal = false {
    template = buildRegexFromTemplate(templateStr);
  }

  bool matches(String pattern) => template.hasMatch(pattern);

  @override
  Iterable<ParamAndValue> resolveParams(final String pattern) sync* {
    for (final param in resolveParamsFromPath(template, pattern)) {
      yield param
        ..value = descriptors.fold(
          param.value,
          (value, descriptor) => descriptor(value),
        );
    }
  }

  @override
  void addRoute<T>(HTTPMethod method, IndexedValue<T> handler) {
    super.addRoute(method, handler);
    _terminal = true;
  }
}

class CompositeParameterDefinition extends ParameterDefinition
    implements HandlerStore {
  final List<SingleParameterDefn> parts;
  final SingleParameterDefn _maybeTerminalPart;

  CompositeParameterDefinition._(this.parts) : _maybeTerminalPart = parts.last;

  @override
  String get templateStr => parts.map((e) => e.templateStr).join();

  @override
  String get name => parts.map((e) => e.name).join('|');

  @override
  String get key => parts.map((e) => e.key).join('|');

  @override
  RegExp get template => buildRegexFromTemplate(templateStr);

  @override
  bool get terminal => _maybeTerminalPart.terminal;

  @override
  Iterable<ParamAndValue> resolveParams(String pattern) sync* {
    for (final param in resolveParamsFromPath(template, pattern)) {
      final defn = parts.firstWhere((e) => e.name == param.param);

      yield param
        ..value = defn.descriptors.fold<dynamic>(
          param.value,
          (value, descriptor) => descriptor(value),
        );
    }
  }

  @override
  void addMiddleware<T>(IndexedValue<T> handler) {
    _maybeTerminalPart.addMiddleware(handler);
  }

  @override
  void addRoute<T>(HTTPMethod method, IndexedValue<T> handler) =>
      _maybeTerminalPart.addRoute(method, handler);

  @override
  IndexedValue? getHandler(HTTPMethod method) =>
      _maybeTerminalPart.getHandler(method);

  @override
  bool hasMethod(HTTPMethod method) => _maybeTerminalPart.hasMethod(method);

  @override
  Iterable<HTTPMethod> get methods => _maybeTerminalPart.methods;
}
