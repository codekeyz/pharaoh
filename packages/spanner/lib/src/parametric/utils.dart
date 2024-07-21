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

Map<String, dynamic>? resolveParamsFromPath(
  RegExp templateRegex,
  String path,
) {
  final match = templateRegex.firstMatch(path);
  if (match == null) return null;

  return {
    for (final param in match.groupNames) param: match.namedGroup(param),
  };
}

extension ParametricDefinitionsExtension on List<ParameterDefinition> {
  void sortByProps() => sort((a, b) {
        // First, prioritize CompositeParameterDefinition
        if (a is CompositeParameterDefinition &&
            b is! CompositeParameterDefinition) {
          return -1;
        }
        if (b is CompositeParameterDefinition &&
            a is! CompositeParameterDefinition) {
          return 1;
        }

        // If both are CompositeParameterDefinition, compare their lengths
        if (a is CompositeParameterDefinition &&
            b is CompositeParameterDefinition) {
          return b.parts.length.compareTo(a.parts.length);
        }

        // Now handle SingleParameterDefn cases
        if (a is SingleParameterDefn && b is SingleParameterDefn) {
          bool aHasPrefix = a.prefix != null;
          bool aHasSuffix = a.suffix != null;
          bool bHasPrefix = b.prefix != null;
          bool bHasSuffix = b.suffix != null;

          int aScore = (aHasPrefix ? 1 : 0) + (aHasSuffix ? 1 : 0);
          int bScore = (bHasPrefix ? 1 : 0) + (bHasSuffix ? 1 : 0);

          return bScore.compareTo(aScore);
        }

        // This case shouldn't occur if all elements are either Composite or Single,
        // but including it for completeness
        return 0;
      });
}
