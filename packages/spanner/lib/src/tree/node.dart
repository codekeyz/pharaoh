import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:pharaoh/pharaoh.dart';

import '../route/action.dart';
import '../parametric/definition.dart';
import '../parametric/utils.dart';

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

class StaticNode extends Node with RouteActionMixin {
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

  void addNewDefinition(ParameterDefinition defn) {
    final existing =
        _definitions.firstWhereOrNull((e) => e.isExactExceptName(defn));

    if (existing != null) {
      if (existing.name != defn.name) {
        throw ArgumentError(
          'Route has inconsistent naming in parameter definition\n${[
            ' - ${existing.templateStr}',
            ' - ${defn.templateStr}',
          ].join('\n')}',
        );
      }

      if (existing.terminal && defn.terminal) {
        throw ArgumentError(
          'Route already exists.${[
            ' - ${existing.templateStr}',
            ' - ${defn.templateStr}',
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
    HTTPMethod method,
    String part, {
    bool shouldBeTerminal = false,
  }) {
    return definitions.firstWhereOrNull(
      (e) {
        final definitionCanHandleMethod =
            e.methods.isEmpty || e.hasMethod(method);

        return definitionCanHandleMethod &&
            e.matches(part, shouldbeTerminal: shouldBeTerminal);
      },
    );
  }
}

// ignore: constant_identifier_names
const String WILDCARD_SYMBOL = '*';

class WildcardNode extends StaticNode {
  WildcardNode() : super(WILDCARD_SYMBOL);

  @override
  String get name => 'wildcard($WILDCARD_SYMBOL)';

  @override
  List<Object?> get props => [name];

  @override
  bool get terminal => true;

  @override
  Node addChildAndReturn(key, node) {
    throw ArgumentError('Wildcard cannot have a child');
  }
}
