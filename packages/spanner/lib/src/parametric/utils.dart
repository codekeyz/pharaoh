import '../tree/utils.dart';
import 'definition.dart';

final parametricRegex = RegExp(r"<[^>]+>");

/// This regex has 3 Groups
///
/// - ([^<]*) -> this captures prefix
///
/// - (\w+(?:\|[^>|]+)*) -> this captures the value within definition
///
/// - ([^<]*) -> this captures suffix
final parametricDefnsRegex = RegExp(r"([^<]*)<(\w+(?:\|[^>|]+)*)>([^<]*)");

final closeDoorParametricRegex = RegExp(r"><");

extension StringExtension on String {
  bool get isStatic => !isParametric && !isWildCard;

  bool get isParametric => parametricRegex.hasMatch(this);

  bool get isWildCard => codeUnitAt(0) == 42;

  bool get isRegex => isRegexeric(this);

  String? get nullIfEmpty => isEmpty ? null : this;
}

/// converts `(^\\w+)` string value to Regex('\w+)
RegExp descriptorToRegex(String descriptor) {
  // Remove leading and trailing parentheses
  String regexStr = descriptor.substring(1, descriptor.length - 1);
  return RegExp(regexStr);
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

Map<String, dynamic> resolveParamsFromPath(RegExp templateRegex, String path) {
  final match = templateRegex.firstMatch(path);
  if (match == null) return const {};

  final resolvedParams = <String, dynamic>{};
  for (final param in match.groupNames) {
    resolvedParams[param] = match.namedGroup(param);
  }
  return resolvedParams;
}

extension ParametricDefinitionsExtension on List<ParameterDefinition> {
  void sortByProps() {
    final Map<int, int> nullCount = {};
    for (final def in this) {
      int count = 0;
      if (def.prefix == null) count += 1;
      if (def.suffix == null) count += 1;
      nullCount[def.hashCode] = count;
    }

    sort((a, b) => nullCount[a.hashCode]!.compareTo(nullCount[b.hashCode]!));
  }

  Iterable get methods => map((e) => e.methods).reduce((val, e) => {...val, ...e});
}
