import 'package:collection/collection.dart';
import 'package:spanner/spanner.dart';

import 'tree.dart';
import '../parametric/definition.dart';
import '../parametric/utils.dart';

part '../route/action.dart';

abstract class Node with HandlerStoreMixin {
  final Map<String, Node> _nodesMap;

  Node() : _nodesMap = {};

  String get route;

  bool terminal = false;

  Iterable<String> get paths => _nodesMap.keys;

  Iterable<Node> get children => _nodesMap.values;

  bool hasChild(String char) => _nodesMap.containsKey(char);

  Node getChild(String char) => _nodesMap[char]!;

  Node? maybeChild(String char) => _nodesMap[char];

  bool get hasChildren => _nodesMap.isNotEmpty;

  ParametricNode? _paramNodecache;
  ParametricNode? get paramNode => _paramNodecache;

  WildcardNode? _wildcardNodeCache;
  WildcardNode? get wildcardNode => _wildcardNodeCache;

  T addChildAndReturn<T extends Node>(String key, T node) {
    if (node is WildcardNode) return _wildcardNodeCache = node;
    if (node is ParametricNode) return _paramNodecache = node;
    return _nodesMap[key] = node;
  }

  @override
  void addRoute<T>(HTTPMethod method, IndexedValue<T> handler) {
    super.addRoute(method, handler);
    terminal = true;
  }

  String _buildFullRoute(String basePath, String nodeRoute) {
    if (basePath == '/') {
      return nodeRoute.startsWith('/') ? nodeRoute : '/$nodeRoute';
    } else {
      return nodeRoute.startsWith('/')
          ? '$basePath$nodeRoute'
          : '$basePath/$nodeRoute';
    }
  }

  String _getRoutes(String basePath, Node node, {int tabIndex = 0}) {
    final buffer = StringBuffer();

    final methods = node.methods;
    final tabSpace = ' ' * tabIndex;
    var routeStr = '$tabSpace└── ${node.route}';
    if (methods.isNotEmpty) {
      final res = methods.map((e) => e.name).join(', ');
      routeStr += ' ($res)';
    }

    buffer.writeln(routeStr);

    for (final child in node.children) {
      final prefix = _buildFullRoute(basePath, node.route);
      final tabIndex = prefix.length == 1 ? 0 : prefix.length + 1;
      buffer.write(_getRoutes(prefix, child, tabIndex: tabIndex));
    }

    final paramNode = node.paramNode;
    final wildcardNode = node.wildcardNode;

    // TODO: add this to route tree print
    if (paramNode != null) {
      final paramBuffer = StringBuffer();
      for (final method in paramNode.methods) {
        final defn = paramNode.definitions(method);

        final newSpace = ' ' * (routeStr.length - 2);
        paramBuffer.write('$newSpace└── <${defn.first.name}> (${method.name})');
      }

      buffer.writeln(paramBuffer);
    }

    // TODO: add this to route tree print
    if (wildcardNode != null) {}

    return buffer.toString();
  }

  String get routes => _getRoutes('/', this);

  @override
  Object get owner => this;
}

class StaticNode extends Node {
  final String _name;

  StaticNode(this._name);

  @override
  String get route => _name;
}

class ParametricNode extends Node {
  static const String key = '<:>';

  final Map<HTTPMethod, List<ParameterDefinition>> _definitionsMap;

  @override
  void addMiddleware<T>(IndexedValue<T> handler) {
    throw ArgumentError('Parametric Node cannot have middlewares');
  }

  @override
  void addRoute<T>(HTTPMethod method, IndexedValue<T> handler) {
    throw ArgumentError('Parametric Node cannot have routes');
  }

  @override
  Iterable<HTTPMethod> get methods => _definitionsMap.keys;

  @override
  T addChildAndReturn<T extends Node>(key, node) {
    if (node is WildcardNode) {
      throw ArgumentError('Parametric Node cannot have wildcard');
    }
    return super.addChildAndReturn(key, node);
  }

  List<ParameterDefinition> definitions(HTTPMethod method) =>
      _definitionsMap[method] ?? const [];

  ParametricNode(HTTPMethod method, ParameterDefinition defn)
      : _definitionsMap = {} {
    addNewDefinition(method, defn, false);
  }

  void addNewDefinition(
    HTTPMethod method,
    ParameterDefinition defn,
    bool terminal,
  ) {
    var definitions = _definitionsMap[method];
    if (definitions == null) {
      definitions = [];
      _definitionsMap[method] = definitions;
    }

    if (definitions.isNotEmpty) {
      /// At this point, terminal in [defn] will always be false since
      /// terminals are only set after we've added a route to the definition.
      ///
      /// So we compare key without terminal and then manually check with the
      /// [terminal] value we have right now.
      final existing = definitions.firstWhereOrNull((e) => e.key == defn.key);
      if (existing != null) {
        if (existing.name != defn.name) {
          throw ArgumentError(
            'Route has inconsistent naming in parameter definition\n${[
              ' - ${existing.templateStr}',
              ' - ${defn.templateStr}',
            ].join('\n')}',
          );
        }

        if (existing.terminal && terminal) {
          throw ArgumentError('Route entry already exists');
        }

        return;
      }
    }

    definitions
      ..add(defn)
      ..sortByProps();
  }

  @override
  String get route => ParametricNode.key;

  ParameterDefinition? findMatchingDefinition(
    HTTPMethod method,
    String part, {
    bool terminal = false,
    bool caseSensitive = false,
    String? nextPart,
  }) {
    return _definitionsMap[method]?.firstWhereOrNull(
      (e) =>
          (!terminal || (e.terminal && e.hasMethod(method))) &&
          e.matches(part, caseSensitive: caseSensitive),
    );
  }
}

class WildcardNode extends StaticNode {
  static const String key = '*';

  WildcardNode() : super(WildcardNode.key);

  @override
  bool get terminal => true;

  @override
  T addChildAndReturn<T extends Node>(key, node) {
    throw ArgumentError('Wildcard cannot have a child');
  }
}
