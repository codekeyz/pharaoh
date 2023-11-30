final _parametricDefnRegex = RegExp(r"([^<]*)(<\w+>)([^<]*)");

class ParametricDefinition {
  final String name;
  final String? prefix;
  final String? suffix;
  final RegExp? regex;
  final bool terminal;

  const ParametricDefinition(
    this.name, {
    this.prefix,
    this.suffix,
    this.regex,
    this.terminal = false,
  });

  bool hasMatch(String pattern, {bool shouldbeTerminal = false}) {
    if (shouldbeTerminal != terminal) return false;

    final expectedSuffix = suffix;
    if (expectedSuffix != null) {
      if (!pattern.endsWith(expectedSuffix)) return false;
    }

    return true;
  }
}

class CompositeParametricDefinition extends ParametricDefinition {
  final List<ParametricDefinition> parts;

  CompositeParametricDefinition(
    ParametricDefinition defn, {
    required this.parts,
  }) : super(
          defn.name,
          regex: defn.regex,
          prefix: defn.prefix,
          suffix: defn.suffix,
          terminal: defn.terminal,
        );

  @override
  bool hasMatch(String pattern, {bool shouldbeTerminal = false}) {
    return false;
  }
}
