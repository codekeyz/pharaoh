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

String buildTemplateString({
  required String name,
  String? prefix,
  String? suffix,
}) {
  var template = '<$name>';
  if (prefix != null) template = "$prefix$template";
  if (suffix != null) template = '$template$suffix';
  return template;
}

RegExp buildRegexFromTemplate(String template) {
  final escapedTemplate = RegExp.escape(template);

  // Replace <...> placeholders with named capturing groups
  final regexPattern = escapedTemplate.replaceAllMapped(
    RegExp(r"<([^>]+)>"),
    (Match match) {
      String paramName = match.group(1)!;
      return "(?<$paramName>[^/]+)";
    },
  );

  return RegExp(regexPattern, caseSensitive: false);
}

Map<String, dynamic> resolveParamsFromPath(RegExp templateRegex, String path) {
  final match = templateRegex.firstMatch(path);
  if (match == null) return const {};
  return {
    for (final param in match.groupNames) param: match.namedGroup(param)!
  };
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
}
