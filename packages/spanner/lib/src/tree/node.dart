import 'package:collection/collection.dart';

import 'tree.dart';
import '../parametric/definition.dart';
import '../parametric/utils.dart';

part '../route/action.dart';

abstract class Node with HandlerStore {
  final Map<String, Node> _nodesMap;

  Node() : _nodesMap = {};

  String get route;

  bool terminal = false;

  Map<String, dynamic> params = {};

  Iterable<String> get paths => _nodesMap.keys;

  Iterable<Node> get children => _nodesMap.values;

  bool hasChild(String char) => _nodesMap.containsKey(char);

  Node getChild(String char) => _nodesMap[char]!;

  Node? maybeChild(String char) => _nodesMap[char];

  bool get hasChildren => _nodesMap.isNotEmpty;

  ParametricNode? _paramNodecache;
  ParametricNode? get paramNode {
    if (_paramNodecache != null) return _paramNodecache;
    return _paramNodecache = _nodesMap.values
        .firstWhereOrNull((e) => e is ParametricNode) as ParametricNode?;
  }

  WildcardNode? _wildcardNodeCache;
  WildcardNode? get wildcardNode {
    if (_wildcardNodeCache != null) return _wildcardNodeCache;
    return _wildcardNodeCache = _nodesMap.values
        .firstWhereOrNull((e) => e is WildcardNode) as WildcardNode?;
  }

  Node addChildAndReturn(String key, Node node) {
    _nodesMap[key] = node;
    return node;
  }
}

class StaticNode extends Node {
  final String _name;

  StaticNode(this._name);

  @override
  String get route => _name;
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
  Iterable<HTTPMethod> get methods => definitions
      .fold<List<HTTPMethod>>([], (preV, e) => preV..addAll(e.methods));

  @override
  Node addChildAndReturn(String key, Node node) {
    if (node is WildcardNode) {
      throw ArgumentError('Parametric Node cannot have wildcard');
    }
    return super.addChildAndReturn(key, node);
  }

  final List<ParameterDefinition> _definitions;

  Iterable<ParameterDefinition> get definitions => _definitions;

  ParametricNode(HTTPMethod method, ParameterDefinition defn)
      : _definitions = [] {
    addNewDefinition(method, defn);
  }

  bool get hasTerminal => _definitions.any((e) => e.terminal);

  void addNewDefinition(HTTPMethod method, ParameterDefinition defn) {
    final existing = _definitions.firstWhereOrNull((e) => e.key == defn.key);
    if (existing != null) {
      if (existing.name != defn.name) {
        throw ArgumentError(
          'Route has inconsistent naming in parameter definition\n${[
            ' - ${existing.templateStr}',
            ' - ${defn.templateStr}',
          ].join('\n')}',
        );
      }

      // Skip method check if defn is not terminal
      if (!existing.terminal) return;

      if (methods.any((e) => e == method)) {
        throw ArgumentError(
          'Definition already exists${[
            ' - ${defn.key}',
            ' - ${defn.templateStr}',
          ].join('\n')}',
        );
      }
    }

    _definitions
      ..add(defn)
      ..sortByProps();
  }

  @override
  String get route => ParametricNode.key;

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
  bool get terminal => true;

  @override
  Node addChildAndReturn(key, node) {
    throw ArgumentError('Wildcard cannot have a child');
  }
}
