class Node<T> {
  Map<String, Node> children = {};

  bool terminal = false;

  T? value;

  bool hasChild(String char) => children.containsKey(char);

  Node getChild(String char) => children[char]!;

  bool get hasChildren => children.isNotEmpty;
}

class ParametricNode extends Node<Map<String, dynamic>> {
  final String name;
  ParametricNode(this.name);
}

class RegexericNode extends Node<Map<String, dynamic>> {
  final String regexStr;
  RegexericNode(this.regexStr);
}
