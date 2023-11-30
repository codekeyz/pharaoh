import 'package:collection/collection.dart';
import 'package:pharaoh_router/src/tree_utils.dart';

abstract class Node<T> {
  Map<String, Node> children = {};

  String get name;

  bool terminal = false;

  T? value;

  bool hasChild(String char) => children.containsKey(char);

  Node getChild(String char) => children[char]!;

  bool get hasChildren => children.isNotEmpty;

  ParametricNode? _paramNodecache;
  ParametricNode? get paramNode {
    if (_paramNodecache != null) return _paramNodecache;
    final node = children.values.firstWhereOrNull((e) => e is ParametricNode);
    if (node == null) return null;
    return _paramNodecache = (node as ParametricNode);
  }

  Node addChildAndReturn(String key, Node node) {
    children[key] = node;
    return node;
  }
}

class StaticNode extends Node<String> {
  final String _name;

  @override
  String get name => 'static($_name)';

  StaticNode(this._name);
}

typedef ParametricDefinition = ({
  String name,
  String? suffix,
  RegExp? regex,
  bool terminal,
});

class ParametricNode extends Node<Map<String, dynamic>> {
  final List<ParametricDefinition> _definitions = [];

  List<ParametricDefinition> get definitions =>
      UnmodifiableListView(_definitions);

  ParametricNode(ParametricDefinition defn) {
    _definitions.add(defn);
  }

  factory ParametricNode.fromPath(String path, {bool terminal = false}) {
    final parameter = getParameter(path)!;
    final remaining = path.substring(parameter.length + 1);

    return ParametricNode((
      name: parameter,
      suffix: remaining,
      regex: null,
      terminal: terminal,
    ));
  }

  void addNewDefinition(String part, {bool terminal = false}) {
    final name = getParameter(part)!;
    final paramLength = '<$name>'.length;
    final isEnd = part.length == paramLength;
    final remaining = isEnd ? null : part.substring(paramLength);

    _definitions.add((
      name: name,
      suffix: remaining,
      regex: null,
      terminal: terminal,
    ));
  }

  @override
  String get name => 'parametric(${_definitions.length})';

  // RegExp? _regexCache;
  // RegExp? get regex {
  //   if (_regexCache != null) return _regexCache;
  //   final source = regsrc;
  //   if (source == null) return null;
  //   final actual = source.substring(1, source.length - 1);
  //   return _regexCache ??= RegExp(RegExp.escape(actual));
  // }
}

extension NodeExtension on Iterable<Node> {
  bool get hasOnlyOneTerminal {
    return length == 1 && first.terminal;
  }
}
