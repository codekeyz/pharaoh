import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

import '../route/action.dart';
import 'utils.dart';

/// build a parametric definition from a route part
ParameterDefinition? _buildParamDefinition(String part, bool terminal) {
  if (closeDoorParametricRegex.hasMatch(part)) {
    throw ArgumentError.value(
        part, null, 'Parameter definition is not valid. Close door neighbors');
  }

  ParameterDefinition makeDefn(RegExpMatch m, {bool end = false}) {
    final sourceParts = m.group(2)!.split('|');

    /// TODO(codekeyz) complete support for regex and parsers
    /// in the remaining parts of [sourceParts]

    return ParameterDefinition._(
      sourceParts.first,
      prefix: m.group(1)?.nullIfEmpty,
      suffix: m.group(3)?.nullIfEmpty,
      terminal: end,
    );
  }

  final matches = parametricDefnsRegex.allMatches(part);
  if (matches.isEmpty) {
    throw ArgumentError.value(part, null, 'Parameter definition is not valid');
  }

  if (matches.length == 1) {
    return makeDefn(matches.first, end: terminal);
  }

  final parent = makeDefn(matches.first, end: false);
  final subdefns = matches.skip(1);
  final subparts = subdefns
      .mapIndexed((i, e) => makeDefn(e, end: i == (subdefns.length - 1)));

  return CompositeParameterDefinition._(
    parent,
    subparts: UnmodifiableListView(subparts),
  );
}

class ParameterDefinition with EquatableMixin, RouteActionMixin {
  final String name;
  final String? prefix;
  final String? suffix;
  final RegExp? regex;
  final bool terminal;

  ParameterDefinition._(
    this.name, {
    this.prefix,
    this.suffix,
    this.regex,
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

  bool matches(String pattern, {bool shouldbeTerminal = false}) {
    if (terminal != shouldbeTerminal) return false;
    return template.hasMatch(pattern);
  }

  bool isExactExceptName(ParameterDefinition defn) {
    return prefix == defn.prefix &&
        suffix == defn.suffix &&
        regex == defn.regex &&
        terminal == defn.terminal &&
        methods.any((e) => defn.methods.contains(e));
  }

  Map<String, dynamic> resolveParams(final String pattern) {
    return resolveParamsFromPath(template, pattern);
  }

  @override
  List<Object?> get props => [name, prefix, suffix, regex, terminal];
}

class CompositeParameterDefinition extends ParameterDefinition {
  final UnmodifiableListView<ParameterDefinition> subparts;

  CompositeParameterDefinition._(
    ParameterDefinition parent, {
    required this.subparts,
  }) : super._(
          parent.name,
          regex: parent.regex,
          prefix: parent.prefix,
          suffix: parent.suffix,
          terminal: false,
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
    return resolveParamsFromPath(template, pattern);
  }

  @override
  bool matches(String pattern, {bool shouldbeTerminal = false}) {
    final match = template.hasMatch(pattern);
    if (!match) return false;
    return shouldbeTerminal && terminal;
  }
}
