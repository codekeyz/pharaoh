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
    throw ArgumentError('Route part is not valid. Closed door neighbors', part);
  }

  final matches = parametricDefnsRegex.allMatches(part);
  if (matches.isEmpty) return null;

  final parent = _createDefinition(matches.first, terminal: terminal);
  if (matches.length == 1) return parent;

  final remainingMatches =
      matches.skip(1).map((e) => _createDefinition(e)).toList();

  return CompositeParametricDefinition(
    parent,
    subparts: remainingMatches,
  );
}

class ParametricDefinition with EquatableMixin {
  final String name;
  final String? prefix;
  final String? suffix;
  final RegExp? regex;
  final bool terminal;

  const ParametricDefinition._(
    this.name, {
    this.prefix,
    this.suffix,
    this.regex,
    this.terminal = false,
  });

  factory ParametricDefinition.from(String part, {bool terminal = false}) {
    return _deriveDefnFromString(part, terminal)!;
  }

  bool matches(String pattern, {bool shouldbeTerminal = false}) {
    if (shouldbeTerminal != terminal) return false;

    final expectedSuffix = suffix;
    if (expectedSuffix != null) {
      if (!pattern.endsWith(expectedSuffix)) return false;
    }

    return true;
  }

  Map<String, dynamic> resolveParams(String pattern) {
    String actualValue = pattern;
    final suffix_ = suffix;
    if (suffix_ != null) {
      if (suffix_.length >= pattern.length) return {};
      actualValue = pattern.substring(0, pattern.length - suffix_.length);
    }
    return {name: actualValue};
  }

  @override
  List<Object?> get props => [name, prefix, suffix, regex, terminal];
}

class CompositeParametricDefinition extends ParametricDefinition {
  final List<ParametricDefinition> subparts;

  CompositeParametricDefinition(ParametricDefinition parent,
      {required this.subparts})
      : super._(
          parent.name,
          regex: parent.regex,
          prefix: parent.prefix,
          suffix: parent.suffix,
          terminal: parent.terminal,
        );

  @override
  bool matches(String pattern, {bool shouldbeTerminal = false}) {
    print('We are here to search');

    return false;
  }

  @override
  List<Object?> get props => [...super.props, subparts];
}
