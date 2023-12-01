import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

import '../tree_utils.dart';

final parametricRegex = RegExp(r"<\w+>");

final parametricDefnsRegex = RegExp(r"([^<]*)(<\w+>)([^<]*)");

final closedDoorParametricRegex = RegExp(r"><");

ParametricDefinition _createDefinition(RegExpMatch m, {bool terminal = false}) {
  final name = getParameter(m.group(2)!)!;
  return ParametricDefinition._(
    name,
    prefix: m.group(1)?.nullIfEmpty,
    suffix: m.group(3)?.nullIfEmpty,
    terminal: terminal,
  );
}

ParametricDefinition? _deriveDefnFromString(String part, bool terminal) {
  if (closedDoorParametricRegex.hasMatch(part)) {
    throw ArgumentError('Route part is not valid. Close door neighbors', part);
  }

  final matches = parametricDefnsRegex.allMatches(part);
  if (matches.isEmpty) return null;

  if (matches.length == 1) {
    return _createDefinition(matches.first, terminal: terminal);
  }

  final parent = _createDefinition(matches.first, terminal: false);
  final subdefns = matches.skip(1);
  final subparts = subdefns.mapIndexed(
      (i, e) => _createDefinition(e, terminal: i == (subdefns.length - 1)));

  return CompositeParametricDefinition(
    parent,
    subparts: UnmodifiableListView(subparts),
  );
}

RegExp buildRegexPattern(String template) {
  String escapedTemplate = RegExp.escape(template);

  // Replace <...> placeholders with named capturing groups
  String regexPattern = escapedTemplate.replaceAllMapped(
    RegExp(r"<([^>]+)>"),
    (Match match) {
      String paramName = match.group(1)!;
      return "(?<$paramName>[^/]+)";
    },
  );

  return RegExp(regexPattern);
}

Map<String, dynamic> resolveParamsFromPath(RegExp templateRegex, String path) {
  final resolvedParams = <String, dynamic>{};
  final match = templateRegex.firstMatch(path)!;
  for (final param in match.groupNames) {
    resolvedParams[param] = match.namedGroup(param);
  }
  return resolvedParams;
}

class ParametricDefinition with EquatableMixin {
  final String name;
  final String? prefix;
  final String? suffix;
  final RegExp? regex;
  final bool terminal;

  ParametricDefinition._(
    this.name, {
    this.prefix,
    this.suffix,
    this.regex,
    this.terminal = false,
  });

  String get template {
    String result = '<$name>';
    if (prefix != null) result = "$prefix$result";
    if (suffix != null) result = '$result$suffix';
    return result;
  }

  RegExp? _paramRegexCache;
  RegExp get paramRegex {
    if (_paramRegexCache != null) return _paramRegexCache!;
    return _paramRegexCache = buildRegexPattern(template);
  }

  factory ParametricDefinition.from(String part, {bool terminal = false}) {
    return _deriveDefnFromString(part, terminal)!;
  }

  bool matches(String pattern, {bool shouldbeTerminal = false}) {
    if (terminal != shouldbeTerminal) return false;
    return paramRegex.hasMatch(pattern);
  }

  Map<String, dynamic> resolveParams(final String pattern) {
    return resolveParamsFromPath(
      paramRegex,
      pattern,
    );
  }

  @override
  List<Object?> get props => [name, prefix, suffix, regex, terminal];
}

class CompositeParametricDefinition extends ParametricDefinition {
  final UnmodifiableListView<ParametricDefinition> subparts;

  CompositeParametricDefinition(
    ParametricDefinition parent, {
    required this.subparts,
  }) : super._(
          parent.name,
          regex: parent.regex,
          prefix: parent.prefix,
          suffix: parent.suffix,
        );

  @override
  List<Object?> get props => [...super.props, subparts];

  @override
  bool get terminal => subparts.any((e) => e.terminal);

  String get compositeTemplate {
    return '$template${subparts.map((e) => e.template).join()}';
  }

  RegExp? _fullParamRegexCache;
  RegExp get fullParamRegex {
    if (_fullParamRegexCache != null) return _fullParamRegexCache!;
    return _fullParamRegexCache = buildRegexPattern(compositeTemplate);
  }

  @override
  Map<String, dynamic> resolveParams(String pattern) {
    return resolveParamsFromPath(
      fullParamRegex,
      pattern,
    );
  }

  @override
  bool matches(String pattern, {bool shouldbeTerminal = false}) {
    final match = fullParamRegex.hasMatch(pattern);
    if (!match) return false;
    return shouldbeTerminal && terminal;
  }
}
