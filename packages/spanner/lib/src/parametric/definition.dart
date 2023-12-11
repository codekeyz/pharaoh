import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

import '../route/action.dart';
import 'descriptor.dart';
import 'utils.dart';

final _knownDescriptors = {'number': numDescriptor};

/// build a parametric definition from a route part
ParameterDefinition? _buildParamDefinition(String part, bool terminal) {
  if (closeDoorParametricRegex.hasMatch(part)) {
    throw ArgumentError.value(
        part, null, 'Parameter definition is invalid. Close door neighbors');
  }

  ParameterDefinition makeDefinition(RegExpMatch m, {bool end = false}) {
    final parts = m.group(2)!.split('|');

    List<ParameterDescriptor> descriptors = [];
    if (parts.length > 1) {
      final result = parts.sublist(1).map((e) {
        final value = e.isRegex ? regexDescriptor : _knownDescriptors[e];
        if (value == null) {
          throw ArgumentError.value(
              e, null, 'Parameter definition has invalid descriptor');
        }
        return value;
      });
      descriptors.addAll(result.cast<ParameterDescriptor>());
    }

    return ParameterDefinition._(
      parts.first,
      prefix: m.group(1)?.nullIfEmpty,
      suffix: m.group(3)?.nullIfEmpty,
      terminal: end,
      descriptors: descriptors,
    );
  }

  final matches = parametricDefnsRegex.allMatches(part);
  if (matches.isEmpty) {
    throw ArgumentError.value(part, null, 'Parameter definition is invalid');
  }

  if (matches.length == 1) {
    return makeDefinition(matches.first, end: terminal);
  }

  final parent = makeDefinition(matches.first, end: false);
  final subdefns = matches.skip(1);
  final subparts = subdefns.mapIndexed(
    (i, e) => makeDefinition(e, end: i == (subdefns.length - 1) && terminal),
  );

  return CompositeParameterDefinition._(parent, subparts: UnmodifiableListView(subparts));
}

class ParameterDefinition with EquatableMixin, HandlerStore {
  final String name;
  final String? prefix;
  final String? suffix;
  final bool terminal;

  final List<ParameterDescriptor> descriptors;

  ParameterDefinition._(
    this.name, {
    this.descriptors = const [],
    this.prefix,
    this.suffix,
    this.terminal = false,
  });

  String get templateStr {
    String result = '<$name>';
    if (prefix != null) result = "$prefix$result";
    if (suffix != null) result = '$result$suffix';
    return result;
  }

  RegExp? _paramRegexCache;
  RegExp get template {
    if (_paramRegexCache != null) return _paramRegexCache!;
    return _paramRegexCache = buildRegexFromTemplate(templateStr);
  }

  factory ParameterDefinition.from(String part, {bool terminal = false}) {
    return _buildParamDefinition(part, terminal)!;
  }

  bool matches(String pattern) => template.hasMatch(pattern);

  bool isExactExceptName(ParameterDefinition defn) {
    if (methods.isNotEmpty) {
      final hasMethod = defn.methods.any((e) => methods.contains(e));
      if (!hasMethod) return false;
    }

    return prefix == defn.prefix && suffix == defn.suffix && terminal == defn.terminal;
  }

  Map<String, dynamic> resolveParams(final String pattern) {
    final params = resolveParamsFromPath(template, pattern);
    params[name] = descriptors.fold<dynamic>(
      params[name],
      (value, descriptor) => descriptor(value),
    );
    return params;
  }

  @override
  List<Object?> get props => [prefix, name, suffix, terminal];
}

class CompositeParameterDefinition extends ParameterDefinition {
  final UnmodifiableListView<ParameterDefinition> subparts;

  CompositeParameterDefinition._(
    ParameterDefinition parent, {
    required this.subparts,
  }) : super._(
          parent.name,
          prefix: parent.prefix,
          suffix: parent.suffix,
          terminal: false,
          descriptors: parent.descriptors,
        );

  @override
  List<Object?> get props => [super.props, ...subparts];

  @override
  bool get terminal => subparts.any((e) => e.terminal);

  @override
  String get templateStr {
    return '${super.templateStr}${subparts.map((e) => e.templateStr).join()}';
  }

  @override
  RegExp get template {
    if (_paramRegexCache != null) return _paramRegexCache!;
    return _paramRegexCache = buildRegexFromTemplate(templateStr);
  }

  @override
  Map<String, dynamic> resolveParams(String pattern) {
    final params = resolveParamsFromPath(template, pattern);
    final definitions = [this, ...subparts].where((e) => e.descriptors.isNotEmpty);
    if (definitions.isNotEmpty) {
      for (final defn in definitions) {
        params[defn.name] = defn.descriptors.fold<dynamic>(
          params[defn.name],
          (value, descriptor) => descriptor(value),
        );
      }
    }
    return params;
  }
}
