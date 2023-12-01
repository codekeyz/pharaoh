import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

import 'helpers/parametric.dart';

abstract class Node with EquatableMixin {
  Map<String, Node> children = {};

  String get name;

  bool _terminal = false;

  bool get isTerminal => _terminal;

  set terminal(bool isend) {
    _terminal = isend;
  }

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

class ParametricNode extends Node {
  final List<ParameterDefinition> _definitions = [];

  List<ParameterDefinition> get definitions =>
      UnmodifiableListView(_definitions);

  ParametricNode(ParameterDefinition defn) {
    _definitions.add(defn);
  }

  factory ParametricNode.fromPath(String path, {bool terminal = false}) {
    return ParametricNode(
      ParameterDefinition.from(path, terminal: terminal),
    );
  }

  void addNewDefinition(String part, {bool terminal = false}) {
    final defn = ParameterDefinition.from(part, terminal: terminal);
    final existing =
        _definitions.firstWhereOrNull((e) => e.isExactExceptName(defn));
    if (existing != null) {
      if (existing.name != defn.name) {
        throw ArgumentError(
          'Route has inconsistent name in parametric definition\n${[
            ' - ${existing.template}',
            ' - ${defn.template}',
          ].join('\n')}',
        );
      }
      return;
    }

    _definitions
      ..add(defn)
      ..sortByProps();
  }

  @override
  String get name => 'parametric(${_definitions.length}-defns)';

  @override
  List<Object?> get props => [name, _definitions, children];

  @override
  bool get isTerminal => _definitions.any((e) => e.terminal);

  ParameterDefinition? findMatchingDefinition(
    String part, {
    bool shouldBeTerminal = false,
  }) =>
      definitions.firstWhereOrNull(
        (e) => e.matches(part, shouldbeTerminal: shouldBeTerminal),
      );
}
