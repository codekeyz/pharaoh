// ignore: constant_identifier_names

// <username> --> username
String? getParameter(String pattern, {int start = 0}) {
  if (start != 0) pattern = pattern.substring(start);
  // <
  if (pattern.codeUnitAt(start) != 60) return null;

  final sb = StringBuffer();
  for (int i = 1; i < pattern.length; i++) {
    // >
    if (pattern.codeUnitAt(i) == 62) break;
    sb.write(pattern[i]);
  }
  return sb.toString();
}

// ::
bool isDoubleColon(String pattern, {int at = 0}) {
  if (at > (pattern.length - 1)) return false;
  final safeNext = (at + 1) < pattern.length;
  return pattern.codeUnitAt(at) == 58 && safeNext && pattern.codeUnitAt(at + 1) == 58;
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
