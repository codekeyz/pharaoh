import 'package:pharaoh/pharaoh.dart';
import 'tree_node.dart';
import 'tree_utils.dart';

class RadixRouterConfig {
  final bool caseSensitive;
  final bool ignoreTrailingSlash;
  final bool ignoreDuplicateSlashes;

  const RadixRouterConfig({
    this.caseSensitive = true,
    this.ignoreTrailingSlash = true,
    this.ignoreDuplicateSlashes = true,
  });
}

class RadixRouter {
  final RadixRouterConfig config;
  final Map<HTTPMethod, Node> _nodeMap = {};

  RadixRouter({
    this.config = const RadixRouterConfig(),
  });

  Node getMethodNode(HTTPMethod method) {
    var node = _nodeMap[method];
    if (node != null) return node;
    return _nodeMap[method] = StaticNode('/');
  }

  void on(HTTPMethod method, String path, {bool debug = false}) {
    path = _cleanPath(path);
    Node root = getMethodNode(method);

    StringBuffer debugLog = StringBuffer();

    void devlog(String message) {
      if (debug) debugLog.writeln(message.toLowerCase());
    }

    devlog('Building node tree for --------- $path --------------');

    final parts = path.split('/');
    for (int i = 0; i < parts.length; i++) {
      final String routePart = parts[i];

      String part = routePart;
      if (!config.caseSensitive) part = part.toLowerCase();

      final parametric = part.isParametric;
      final key = parametric ? '<:>' : part;
      final isLastPart = i == (parts.length - 1);

      void assignNewRoot(Node node) {
        root = root.addChildAndReturn(key, node);
        devlog('- Root node is now ${node.name}');
      }

      var child = root.children[part];
      if (child != null) {
        devlog('- Found node for $part');
        assignNewRoot(child);
      } else {
        devlog('- Found no static node for $part');

        if (!parametric) {
          child = StaticNode(key);
          assignNewRoot(child);
          continue;
        }

        devlog('- $part is parametric');

        final paramNode = root.paramNode;
        if (paramNode == null) {
          devlog('- No existing parametric on ${root.name} so we create one');

          assignNewRoot(ParametricNode.fromPath(
            routePart,
            terminal: isLastPart,
          ));
          continue;
        }

        paramNode.addNewDefinition(routePart, terminal: isLastPart);

        devlog('- Found & updated parametric definitions');
        devlog(
            '- Parametric definitions now ↓\n    ${paramNode.definitions.join('\n    ')}');

        assignNewRoot(paramNode);
      }
    }

    /// special case here because for parametric nodes,
    /// the terminal is within each parametric definition
    if (root is StaticNode) root.terminal = true;

    if (debug) print(debugLog);
  }

  Node? lookup(HTTPMethod method, String path, {bool debug = false}) {
    Node rootNode = getMethodNode(method);
    String route = _cleanPath(path);

    Map<String, dynamic> resolvedParams = {};

    final debugLog = StringBuffer("\n");

    void devlog(String message) {
      if (debug) debugLog.writeln(message.toLowerCase());
    }

    devlog('Finding node for ---------  ${method.name} $route ------------\n');

    final parts = route.split('/');

    for (int i = 0; i < parts.length; i++) {
      final String currPart = parts[i];

      var routePart = currPart;
      if (!config.caseSensitive) routePart = routePart.toLowerCase();

      final hasStaticChild = rootNode.hasChild(routePart);
      final isEndOfPath = i == (parts.length - 1);

      if (hasStaticChild) {
        rootNode = rootNode.getChild(routePart);
        devlog('- Found Static for             ->              $routePart');
      } else {
        final paramNode = rootNode.paramNode;
        final shouldBeTerminal = isEndOfPath;
        if (paramNode == null) {
          devlog('x Found no static node for part       ->         $routePart');
          devlog('x Route is not registered             ->         $route');
          break;
        }

        final hasChild = paramNode.hasChild(routePart);
        if (hasChild) {
          devlog('- Found Static for             ->              $routePart');
          rootNode = paramNode.getChild(routePart);
          continue;
        }

        devlog(
            '- Finding Defn for $routePart        -> terminal?    $shouldBeTerminal');

        final paramDefn = paramNode.findMatchingDefinition(routePart,
            shouldBeTerminal: isEndOfPath);

        devlog('    * parametric defn:         ${paramDefn.toString()}');

        if (paramDefn == null) {
          devlog('x Found no defn for route part      ->         $routePart');
          devlog('x Route is not registered             ->         $route');
          return null;
        }

        devlog('- Found defn for route part    ->              $routePart');

        final params = paramDefn.resolveParams(currPart);
        resolvedParams.addAll(params);
        rootNode = paramNode;

        if (paramDefn.terminal) rootNode.terminal = true;
      }
    }

    if (debug) print(debugLog);

    if (!rootNode.terminal) return null;
    return rootNode..params = resolvedParams;
  }

  void printTree() {
    _nodeMap.forEach(
      (key, value) => _printNode(value, '${key.name} '),
    );
  }

  void _printNode(Node node, String prefix) {
    final isTerminal = node.terminal ||
        (node is ParametricNode && node.definitions.any((e) => e.terminal));
    if (isTerminal) print('$prefix*');

    node.children.forEach(
      (char, node) {
        _printNode(node, '$prefix$char -> ');
      },
    );
  }

  String _cleanPath(String path) {
    if (config.ignoreDuplicateSlashes) {
      path = path.replaceAll(RegExp(r'/+'), '/');
    }
    if (config.ignoreTrailingSlash) {
      path = path.replaceAll(RegExp(r'/+$'), '');
    }

    return path.substring(1);
  }
}
