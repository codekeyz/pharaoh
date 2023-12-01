import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

import '../tree_utils.dart';

final parametricRegex = RegExp(r"<\w+>");

final parametricDefnsRegex = RegExp(r"([^<]*)(<\w+>)([^<]*)");

final closeDoorParametricRegex = RegExp(r"><");

/// build a parametric definition from a route part
ParametricDefinition? deriveDefnFromString(String part, bool terminal) {
  if (closeDoorParametricRegex.hasMatch(part)) {
    throw ArgumentError('Route part is not valid. Close door neighbors', part);
  }

  ParametricDefinition makeDefn(RegExpMatch m, {bool end = false}) {
    final name = getParameter(m.group(2)!)!;
    return ParametricDefinition._(
      name,
      prefix: m.group(1)?.nullIfEmpty,
      suffix: m.group(3)?.nullIfEmpty,
      terminal: end,
    );
  }

  final matches = parametricDefnsRegex.allMatches(part);
  if (matches.isEmpty) return null;

  if (matches.length == 1) {
    return makeDefn(matches.first, end: terminal);
  }

  final parent = makeDefn(matches.first, end: false);
  final subdefns = matches.skip(1);
  final subparts = subdefns
      .mapIndexed((i, e) => makeDefn(e, end: i == (subdefns.length - 1)));

  return CompositeParametricDefinition(
    parent,
    subparts: UnmodifiableListView(subparts),
  );
}

RegExp buildRegexFromTemplate(String template) {
  String escapedTemplate = RegExp.escape(template);

  // Replace <...> placeholders with named capturing groups
  final regexPattern = escapedTemplate.replaceAllMapped(
    RegExp(r"<([^>]+)>"),
    (Match match) {
      String paramName = match.group(1)!;
      return "(?<$paramName>[^/]+)";
    },
  );

  /// TODO(codekeyz) figure out if we need to pass the case sensitivity flag
  /// from the wider context down here or it's safe to keep it case insensitive.
  return RegExp(regexPattern, caseSensitive: false);
}

extension ParametricDefinitionsSort on List<ParametricDefinition> {
  void sortByProps() {
    final Map<int, int> nullCount = {};
    for (final def in this) {
      int count = 0;
      if (def.suffix == null) count += 1;
      if (def.regex == null) count += 1;
      nullCount[def.hashCode] = count;
    }

    sort((a, b) => nullCount[a.hashCode]!.compareTo(nullCount[b.hashCode]!));
  }
}

Map<String, dynamic> resolveParamsFromPath(RegExp templateRegex, String path) {
  final match = templateRegex.firstMatch(path);
  if (match == null) return const {};

  final resolvedParams = <String, dynamic>{};
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
    return _paramRegexCache = buildRegexFromTemplate(template);
  }

  factory ParametricDefinition.from(String part, {bool terminal = false}) {
    return deriveDefnFromString(part, terminal)!;
  }

  bool matches(String pattern, {bool shouldbeTerminal = false}) {
    if (terminal != shouldbeTerminal) return false;
    return paramRegex.hasMatch(pattern);
  }

  bool isExactExceptName(ParametricDefinition defn) {
    return prefix == defn.prefix &&
        suffix == defn.suffix &&
        regex == defn.regex &&
        terminal == defn.terminal;
  }

  Map<String, dynamic> resolveParams(final String pattern) {
    return resolveParamsFromPath(paramRegex, pattern);
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

  @override
  String get template {
    return '${super.template}${subparts.map((e) => e.template).join()}';
  }

  @override
  RegExp get paramRegex {
    if (_paramRegexCache != null) return _paramRegexCache!;
    return _paramRegexCache = buildRegexFromTemplate(template);
  }

  @override
  Map<String, dynamic> resolveParams(String pattern) {
    return resolveParamsFromPath(
      paramRegex,
      pattern,
    );
  }

  @override
  bool matches(String pattern, {bool shouldbeTerminal = false}) {
    final match = paramRegex.hasMatch(pattern);
    if (!match) return false;
    return shouldbeTerminal && terminal;
  }
}
