class Node<T> {
  Map<String, Node> children = {};

  bool terminal = false;

  T? value;

  bool hasChild(String char) => children.containsKey(char);

  Node getChild(String char) => children[char]!;

  bool get hasChildren => children.isNotEmpty;

  void addNode(String char, Node node) => children[char] = node;

  Node? search(String path) {
    Node root = this;
    for (int i = 0; i < path.length; i++) {
      final char = path[i];
      if (root.hasChild(char)) root = root.children[char]!;
    }
    return root.terminal ? root : null;
  }
}

class ParametricNode extends Node<Map<String, dynamic>> {
  final String name;
  ParametricNode(this.name);
}
