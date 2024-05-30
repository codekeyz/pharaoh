import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

import 'tree.dart';
import '../parametric/definition.dart';
import '../parametric/utils.dart';

part '../route/action.dart';

abstract class Node with EquatableMixin, HandlerStore {
  final _indexList = <String>[];
  final _childList = <Node>[];

  String get route;

  bool terminal = false;

  Map<String, dynamic> params = {};

  UnmodifiableListView<String> get paths => UnmodifiableListView(_indexList);

  UnmodifiableListView<Node> get children => UnmodifiableListView(_childList);

  bool hasChild(String char) => _indexList.contains(char);

  Node getChild(String char) => _childList[_indexList.indexOf(char)];

  Node? maybeChild(String char) {
    final indexOfChar = _indexList.indexOf(char);
    return indexOfChar == -1 ? null : _childList[indexOfChar];
  }

  bool get hasChildren => _childList.isNotEmpty;

  ParametricNode? _paramNodecache;
  ParametricNode? get paramNode {
    if (_paramNodecache != null) return _paramNodecache;
    return _paramNodecache = _childList
        .firstWhereOrNull((e) => e is ParametricNode) as ParametricNode?;
  }

  WildcardNode? _wildcardNodeCache;
  WildcardNode? get wildcardNode {
    if (_wildcardNodeCache != null) return _wildcardNodeCache;
    return _wildcardNodeCache =
        _childList.firstWhereOrNull((e) => e is WildcardNode) as WildcardNode?;
  }

  Node addChildAndReturn(String key, Node node) {
    _indexList.add(key);
    _childList.add(node);
    return node;
  }
}

class StaticNode extends Node {
  final String _name;

  StaticNode(this._name);

  @override
  String get route => _name;

  @override
  List<Object?> get props => [route, _childList];
}

class ParametricNode extends Node {
  static final String key = '<:>';

  @override
  void addMiddleware<T>(IndexedValue<T> handler) {
    throw ArgumentError('Parametric Node cannot have middlewares');
  }

  @override
  void addRoute<T>(HTTPMethod method, IndexedValue<T> handler) {
    throw ArgumentError('Parametric Node cannot have routes');
  }

  @override
  Node addChildAndReturn(String key, Node node) {
    if (node is WildcardNode) {
      throw ArgumentError('Parametric Node cannot have wildcard');
    }
    return super.addChildAndReturn(key, node);
  }

  final List<ParameterDefinition> _definitions = [];

  List<ParameterDefinition> get definitions =>
      UnmodifiableListView(_definitions);

  ParametricNode(ParameterDefinition defn) {
    _definitions.add(defn);
  }

  bool get hasTerminal => _definitions.any((e) => e.terminal);

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
  String get route => ParametricNode.key;

  @override
  List<Object?> get props => [route, _definitions, _childList];

  ParameterDefinition? findMatchingDefinition(
    HTTPMethod method,
    String part, {
    bool terminal = false,
  }) {
    return definitions.firstWhereOrNull(
      (e) {
        final supportsMethod = e.methods.isEmpty || e.hasMethod(method);
        if (terminal != e.terminal || !supportsMethod) return false;
        return e.matches(part);
      },
    );
  }
}

class WildcardNode extends StaticNode {
  static final String key = '*';

  WildcardNode() : super(WildcardNode.key);

  @override
  List<Object?> get props => [route];

  @override
  bool get terminal => true;

  @override
  IndexedValue? getHandler(HTTPMethod method) {
    return super.getHandler(method) ?? super.getHandler(HTTPMethod.ALL);
  }

  @override
  Node addChildAndReturn(key, node) {
    throw ArgumentError('Wildcard cannot have a child');
  }
}
