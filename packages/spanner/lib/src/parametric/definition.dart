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

  final defns = matches.map(_singleParamDefn);
  final partsMap = {for (final defn in defns) defn.name: defn};

  return CompositeParameterDefinition._(partsMap, defns.last.name);
}

abstract class ParameterDefinition implements HandlerStore {
  String get name;

  String get templateStr;

  RegExp get template;

  String get key;

  bool get terminal;

  Map<String, dynamic>? resolveParams(String pattern);
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
  Map<String, dynamic>? resolveParams(final String pattern) {
    final params = resolveParamsFromPath(template, pattern);
    if (params == null) return null;

    return params
      ..[name] = descriptors.fold(
        params[name],
        (value, descriptor) => descriptor(value),
      );
  }

  @override
  void addRoute<T>(HTTPMethod method, IndexedValue<T> handler) {
    super.addRoute(method, handler);
    _terminal = true;
  }
}

class CompositeParameterDefinition extends ParameterDefinition
    implements HandlerStore {
  final Map<String, SingleParameterDefn> parts;
  final String _lastPartKey;

  SingleParameterDefn get _maybeTerminalPart => parts[_lastPartKey]!;

  CompositeParameterDefinition._(this.parts, this._lastPartKey);

  @override
  String get templateStr => parts.values.map((e) => e.templateStr).join();

  @override
  String get name => parts.values.map((e) => e.name).join('|');

  @override
  String get key => parts.values.map((e) => e.key).join('|');

  @override
  RegExp get template => buildRegexFromTemplate(templateStr);

  @override
  bool get terminal => _maybeTerminalPart.terminal;

  @override
  Map<String, dynamic>? resolveParams(String pattern) {
    final result = resolveParamsFromPath(template, pattern);
    if (result == null) return null;

    for (final param in result.keys) {
      final defn = parts[param]!;
      final value = result[param];

      result[param] = defn.descriptors.fold<dynamic>(
        value,
        (value, fn) => fn(value),
      );
    }

    return result;
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
