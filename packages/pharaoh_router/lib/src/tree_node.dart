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

  List<ParametricNode> get paramNodes =>
      !hasChildren ? [] : children.values.whereType<ParametricNode>().toList();
}

class StaticNode extends Node<String> {
  final String _name;

  @override
  String get name => 'static($_name)';

  StaticNode(this._name);
}

typedef ParametricDefinition = ({String name, String? suffix, RegExp? regex});

class ParametricNode extends Node<Map<String, dynamic>> {
  final List<ParametricDefinition> _definitions = [];

  List<ParametricDefinition> get definitions =>
      UnmodifiableListView(_definitions);

  ParametricNode(ParametricDefinition defn) {
    _definitions.add(defn);
  }

  factory ParametricNode.fromPath(String path) {
    final name = getPathParameter(path, start: 1);
    final remaining = path.substring(name.length + 1);
    return ParametricNode((name: name, suffix: remaining, regex: null));
  }

  void addNewDefinition(String part) {
    final name = getPathParameter(part, start: 1);
    final paramLength = name.length + 1;
    final isEnd = part.length == paramLength;
    final remaining = isEnd ? null : part.substring(paramLength);
    _definitions.add((name: name, suffix: remaining, regex: null));
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
