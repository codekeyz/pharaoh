import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:pharaoh/pharaoh.dart';

import '../helpers/parametric.dart';

abstract class Node with EquatableMixin {
  final Map<String, Node> _children = {};

  Map<String, Node> get children => UnmodifiableMapView(_children);

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

  WildcardNode? _wildcardNodeCache;
  WildcardNode? get wildcardNode {
    if (_wildcardNodeCache != null) return _wildcardNodeCache;
    final node = children.values.firstWhereOrNull((e) => e is WildcardNode);
    if (node == null) return null;
    return _wildcardNodeCache = (node as WildcardNode);
  }

  Node addChildAndReturn(String key, Node node) {
    _children[key] = node;
    return node;
  }
}

class StaticNode extends Node {
  final List<RouteHandler> _handlers = [];

  final String _name;

  List<RouteHandler> get handlers => UnmodifiableListView(_handlers);

  @override
  String get name => 'static($_name)';

  StaticNode(this._name);

  @override
  List<Object?> get props => [name, children];

  void addHandler(RouteHandler handler) {
    _handlers.add(handler);
  }
}

class ParametricNode extends Node {
  final List<ParameterDefinition> _definitions = [];

  List<ParameterDefinition> get definitions =>
      UnmodifiableListView(_definitions);

  ParametricNode(ParameterDefinition defn) {
    _definitions.add(defn);
  }

  /// This will return false if the definition is known
  void addNewDefinition(String part, {bool terminal = false}) {
    final defn = ParameterDefinition.from(part, terminal: terminal);
    final existing =
        _definitions.firstWhereOrNull((e) => e.isExactExceptName(defn));
    if (existing != null) {
      if (existing.name != defn.name) {
        throw ArgumentError(
          'Route has inconsistent naming in parameter definition\n${[
            ' - ${existing.template}',
            ' - ${defn.template}',
          ].join('\n')}',
        );
      }

      if (existing.terminal && defn.terminal) {
        throw ArgumentError(
          'Route already exists.${[
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

  ParameterDefinition? findMatchingDefinition(
    String part, {
    bool shouldBeTerminal = false,
  }) =>
      definitions.firstWhereOrNull(
        (e) => e.matches(part, shouldbeTerminal: shouldBeTerminal),
      );
}

class WildcardNode extends StaticNode {
  WildcardNode() : super('*');

  @override
  String get name => 'wildcard(*)';

  @override
  List<Object?> get props => [name];

  @override
  bool get terminal => true;

  @override
  Node addChildAndReturn(key, node) {
    throw ArgumentError('Wildcard cannot have a child');
  }
}
