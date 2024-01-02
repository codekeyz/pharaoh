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

bool isRegexeric(String pattern, {int at = 0}) {
  if (at > (pattern.length - 1)) return false;
  return pattern.codeUnitAt(at) == 40;
}
