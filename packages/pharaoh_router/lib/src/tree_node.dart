class Node<T> {
  Map<String, Node> children = {};

  bool terminal = false;

  T? value;

  bool hasChild(String char) => children.containsKey(char);

  Node getChild(String char) => children[char]!;

  bool get hasChildren => children.isNotEmpty;

  List<ParametricNode> get paramNodes =>
      !hasChildren ? [] : children.values.whereType<ParametricNode>().toList();
}

class ParametricNode extends Node<Map<String, dynamic>> {
  final String name;
  final String? regsrc;

  ParametricNode(this.name, {this.regsrc});

  RegExp? _regexCache;
  RegExp? get regex {
    if (_regexCache != null) return _regexCache;
    final source = regsrc;
    if (source == null) return null;
    final actual = source.substring(1, source.length - 1);
    return _regexCache ??= RegExp(RegExp.escape(actual));
  }
}

extension NodeExtension on Iterable<Node> {
  bool get hasOnlyOneTerminal {
    return length == 1 && first.terminal;
  }
}
