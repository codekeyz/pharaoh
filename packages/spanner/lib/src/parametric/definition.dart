import 'package:collection/collection.dart';

import '../tree/node.dart';
import 'descriptor.dart';
import 'utils.dart';

final _knownDescriptors = {'number': numDescriptor};

ParameterDefinition _makeParametricDefn(RegExpMatch m, {bool end = false}) {
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

  return ParameterDefinition._(
    param,
    prefix: m.group(1)?.nullIfEmpty,
    suffix: m.group(3)?.nullIfEmpty,
    terminal: end,
    descriptors: descriptors ?? const [],
  );
}

/// build a parametric definition from a route part
ParameterDefinition buildParamDefinition(String part, bool terminal) {
  if (closeDoorParametricRegex.hasMatch(part)) {
    throw ArgumentError.value(
        part, null, 'Parameter definition is invalid. Close door neighbors');
  }

  final matches = parametricDefnsRegex.allMatches(part);
  if (matches.isEmpty) {
    throw ArgumentError.value(part, null, 'Parameter definition is invalid');
  }

  if (matches.length == 1) {
    return _makeParametricDefn(matches.first, end: terminal);
  }

  final parent = _makeParametricDefn(matches.first, end: false);
  final subdefns = matches.skip(1);
  final subparts = subdefns.mapIndexed(
    (i, e) =>
        _makeParametricDefn(e, end: i == (subdefns.length - 1) && terminal),
  );

  return CompositeParameterDefinition._(parent, subparts: subparts);
}

class ParameterDefinition with HandlerStore {
  final String name;
  final String? prefix;
  final String? suffix;
  final bool terminal;

  final Iterable<ParameterDescriptor> descriptors;

  final String key;
  final String templateStr;

  late final RegExp template;

  ParameterDefinition._(
    this.name, {
    this.descriptors = const [],
    this.prefix,
    this.suffix,
    this.terminal = false,
  })  : key = 'prefix=$prefix&suffix=$suffix&terminal=&$terminal',
        templateStr = buildTemplateString(
          name: name,
          prefix: prefix,
          suffix: suffix,
        ) {
    template = buildRegexFromTemplate(templateStr);
  }

  bool matches(String pattern) => template.hasMatch(pattern);

  Iterable<ParamAndValue> resolveParams(final String pattern) sync* {
    for (final param in resolveParamsFromPath(template, pattern)) {
      yield param
        ..value = descriptors.fold(
          param.value,
          (value, descriptor) => descriptor(value),
        );
    }
  }
}

class CompositeParameterDefinition extends ParameterDefinition {
  final Iterable<ParameterDefinition> subparts;
  final List<ParameterDefinition> _allDefinitions;

  CompositeParameterDefinition._(
    ParameterDefinition parent, {
    required this.subparts,
  })  : _allDefinitions = [parent, ...subparts],
        super._(
          parent.name,
          prefix: parent.prefix,
          suffix: parent.suffix,
          terminal: subparts.any((e) => e.terminal),
          descriptors: parent.descriptors,
        );

  @override
  String get templateStr {
    return '${super.templateStr}${subparts.map((e) => e.templateStr).join()}';
  }

  @override
  Iterable<ParamAndValue> resolveParams(String pattern) sync* {
    for (final param in resolveParamsFromPath(template, pattern)) {
      final defn = _allDefinitions.firstWhere((e) => e.name == param.param);

      yield param
        ..value = defn.descriptors.fold<dynamic>(
          param.value,
          (value, descriptor) => descriptor(value),
        );
    }
  }
}
