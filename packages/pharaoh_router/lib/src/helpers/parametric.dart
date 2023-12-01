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
    throw ArgumentError('Route part is not valid. Closed door neighbors', part);
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
    final prefixMatches = prefix == null || pattern.startsWith(prefix!);
    final suffixMatches = suffix == null || pattern.endsWith(suffix!);
    return prefixMatches && suffixMatches && shouldbeTerminal == terminal;
  }

  Map<String, dynamic> resolveParams(final String pattern) {
    String partLeftAsResult = pattern;

    partLeftAsResult = prefix != null
        ? partLeftAsResult.substring(prefix!.length)
        : partLeftAsResult;

    partLeftAsResult = suffix != null
        ? partLeftAsResult.substring(
            0, partLeftAsResult.length - suffix!.length)
        : partLeftAsResult;

    return {name: partLeftAsResult};
  }

  @override
  List<Object?> get props => [name, prefix, suffix, regex, terminal];
}

class CompositeParametricDefinition extends ParametricDefinition {
  final UnmodifiableListView<ParametricDefinition> subparts;

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
  List<Object?> get props => [...super.props, subparts];
}
