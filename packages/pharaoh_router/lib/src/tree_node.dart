import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:pharaoh_router/src/tree_utils.dart';

import 'helpers/parametric.dart';

abstract class Node with EquatableMixin {
  Map<String, Node> children = {};

  String get name;

  bool terminal = false;

  Map<String, dynamic> params = {};

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

class StaticNode extends Node {
  final String _name;

  @override
  String get name => 'static($_name)';

  StaticNode(this._name);

  @override
  List<Object?> get props => [name, children];
}

typedef ParamAndRemaining = ({String param, String? remaining});

ParamAndRemaining getParamAndRemainingPart(String pattern) {
  final name = getParameter(pattern)!;
  final paramLength = '<$name>'.length;
  final isEnd = pattern.length == paramLength;
  final remaining = isEnd ? null : pattern.substring(paramLength);
  return (param: name, remaining: remaining);
}

void sortParametricDefinition(List<ParametricDefinition> definitions) {
  final Map<int, int> nullCount = {};
  for (final def in definitions) {
    int count = 0;
    if (def.suffix == null) count += 1;
    if (def.regex == null) count += 1;
    nullCount[def.hashCode] = count;
  }
  definitions
      .sort((a, b) => nullCount[a.hashCode]!.compareTo(nullCount[b.hashCode]!));
}

class ParametricNode extends Node {
  final List<ParametricDefinition> _definitions = [];

  List<ParametricDefinition> get definitions =>
      UnmodifiableListView(_definitions);

  ParametricNode(ParametricDefinition defn) {
    _definitions.add(defn);
  }

  factory ParametricNode.fromPath(String path, {bool terminal = false}) {
    final defn = ParametricDefinition.from(path, terminal: terminal);
    return ParametricNode(defn);
  }

  void addNewDefinition(String part, {bool terminal = false}) {
    final defn = ParametricDefinition.from(part, terminal: terminal);
    _definitions.add(defn);
    sortParametricDefinition(_definitions);
  }

  @override
  String get name => 'parametric(${_definitions.length})';

  @override
  List<Object?> get props => [name, _definitions, children];

  // RegExp? _regexCache;
  // RegExp? get regex {
  //   if (_regexCache != null) return _regexCache;
  //   final source = regsrc;
  //   if (source == null) return null;
  //   final actual = source.substring(1, source.length - 1);
  //   return _regexCache ??= RegExp(RegExp.escape(actual));
  // }
}
