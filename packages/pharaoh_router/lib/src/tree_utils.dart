// <username>
import 'helpers/parametric_defn.dart';
import 'tree_node.dart';

bool isParametric(String pattern, {int start = 0}) {
  return pattern.codeUnitAt(start) == 60;
}

// <username> --> username
String? getParameter(String pattern, {int start = 0}) {
  if (start != 0) pattern = pattern.substring(start);
  if (!isParametric(pattern)) return null;

  final sb = StringBuffer();
  for (int i = 1; i < pattern.length; i++) {
    if (pattern.codeUnitAt(i) == 62) break;
    sb.write(pattern[i]);
  }
  return sb.toString();
}

// ::
bool isDoubleColon(String pattern, {int at = 0}) {
  if (at > (pattern.length - 1)) return false;
  final safeNext = (at + 1) < pattern.length;
  return pattern.codeUnitAt(at) == 58 &&
      safeNext &&
      pattern.codeUnitAt(at + 1) == 58;
}

bool isRegexeric(String pattern, {int at = 0}) {
  if (at > (pattern.length - 1)) return false;
  return pattern.codeUnitAt(at) == 40;
}

// *
bool isWildCard(String pattern, {int at = 0}) {
  if (at > (pattern.length - 1)) return false;
  return pattern.codeUnitAt(at) == 42;
}

final alphanumericRegex = RegExp(r'[a-zA-Z0-9]');
bool isAlphabetic(String character) {
  return alphanumericRegex.hasMatch(character);
}

/// `:name/foo/bar` --> `name`
///
/// `:user/`    --> `user`
String getPathParameter(String pattern, {int start = 0}) {
  final length = pattern.length;
  if (start > (length - 1)) {
    throw RangeError('Index is out of bounds of $pattern');
  }
  final sb = StringBuffer();
  for (int i = start; i < length; i++) {
    final char = pattern[i];
    if (!isAlphabetic(char)) break;
    sb.write(char);
  }
  return sb.toString();
}

final symbolRegex = RegExp(r'[@/_.-]');

typedef IndexedSymbol = ({String char, int index});

List<IndexedSymbol> extractIndexedSymbols(String pattern) {
  final List<IndexedSymbol> result = [];
  for (int i = 0; i < pattern.length; i++) {
    final char = pattern[i];
    if (!symbolRegex.hasMatch(char)) continue;
    result.add((index: i, char: char));
  }
  return result;
}

int getClosingParenthesisPosition(String path, int idx) {
  /// track the number of opening parenthesis we have seen
  int parentheses = 1;

  while (++idx < path.length) {
    if (path[idx] == '\\') {
      idx++; // skip escaped characters
    } else if (path[idx] == '(') {
      parentheses++;
    } else if (path[idx] == ')' && --parentheses == 0) {
      return idx;
    }
  }

  throw ArgumentError('Invalid regexp expression in "$path"');
}

dynamic resolveActualParamValue(ParametricDefinition defn, String pattern) {
  String actualValue = pattern;
  final suffix = defn.suffix;
  if (suffix != null) {
    if (suffix.length >= pattern.length) return null;
    actualValue = pattern.substring(0, pattern.length - suffix.length);
  }
  return actualValue;
}

ParametricDefinition? findMatchingParametricDefinition(
  ParametricNode node,
  String pattern, {
  bool terminal = false,
}) {
  final defns = node.definitions;

  ParametricDefinition? result;
  for (final defn in defns) {
    if (terminal != defn.terminal) continue;

    final expectedSuffix = defn.suffix;
    if (expectedSuffix != null) {
      if (!pattern.endsWith(expectedSuffix)) continue;
    }
    result = defn;
    break;
  }

  return result;
}
