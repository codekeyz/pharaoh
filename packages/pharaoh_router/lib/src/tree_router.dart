import 'package:collection/collection.dart';
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
    path = cleanPath(path);
    Node root = getMethodNode(method);

    StringBuffer debugLog = StringBuffer();

    void devlog(String message) {
      if (debug) debugLog.writeln(message.toLowerCase());
    }

    devlog('Building node tree for --------- $path --------------');

    final parts = path.split('/');
    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      final parametric = isParametric(part);
      final key = parametric ? ':' : part;
      final isLastPart = i == (parts.length - 1);

      void assignNewRoot(Node node) {
        root = root.addChildAndReturn(key, node);
        devlog('- Root node is now ${node.name}');
      }

      devlog('- Find node for $part');

      var child = root.children[part];
      if (child == null) {
        devlog('- Found no node for $part');

        if (!parametric) {
          child = StaticNode(key);
          assignNewRoot(child);
        } else {
          devlog('- $part is parametric');

          final paramNode = root.paramNode;
          if (paramNode == null) {
            devlog('- No existing parametric on ${root.name} so we create one');

            assignNewRoot(ParametricNode.fromPath(part, terminal: isLastPart));
            continue;
          }

          paramNode.addNewDefinition(part, terminal: isLastPart);

          devlog('- Found & updated definitions to ${paramNode.name}');
          assignNewRoot(paramNode);
        }
      } else {
        devlog('- Found node for $part');

        assignNewRoot(child);
      }
    }

    root.terminal = true;

    if (debug) print(debugLog);
  }

  Node? lookup(HTTPMethod method, String path, {bool debug = false}) {
    Node rootNode = getMethodNode(method);
    String route = cleanPath(path);

    Map<String, String> resolvedParams = {};

    final debugLog = StringBuffer("\n");

    void devlog(String message) {
      if (debug) debugLog.writeln(message.toLowerCase());
    }

    devlog('Finding node for ---------  ${method.name} $route ------------\n');

    final parts = route.split('/');

    for (int i = 0; i < parts.length; i++) {
      final currPart = parts[i];
      final hasStaticChild = rootNode.hasChild(currPart);
      final isEndOfPath = i == (parts.length - 1);
      final nextPart = isEndOfPath ? null : parts[i + 1];

      if (hasStaticChild) {
        rootNode = rootNode.getChild(currPart);
        devlog('- Found Static for             ->              $currPart');
      } else {
        final paramNode = rootNode.paramNode;
        final shouldBeTerminal = isEndOfPath;
        if (paramNode == null) return null;

        devlog(
            '- Finding Defn for $currPart -> should be terminal?    $shouldBeTerminal');

        final maybeStatic = paramNode.definitions.firstWhereOrNull(
          (e) => e.terminal == shouldBeTerminal && nextPart == null,
        );

        if (maybeStatic != null) {
          devlog('- Found defn for route part    ->              $currPart');

          resolvedParams[maybeStatic.name] = currPart;
          paramNode.value = resolvedParams;
          rootNode = paramNode;
          if (maybeStatic.terminal) break;
        }
      }
    }

    if (debug) print(debugLog);

    if (!rootNode.terminal) return null;

    return rootNode;
    // return rootNode..value = resolvedParams;
  }

  void printTree() {
    _nodeMap.forEach(
      (key, value) => _printNode(value, '${key.name} '),
    );
  }

  void _printNode(Node node, String prefix) {
    if (node.terminal) print('$prefix*');

    node.children.forEach(
      (char, node) {
        _printNode(node, '$prefix$char -> ');
      },
    );
  }

  String cleanPath(String path) {
    if (config.ignoreDuplicateSlashes) {
      path = path.replaceAll(RegExp(r'/+'), '/');
    }
    if (config.ignoreTrailingSlash) {
      path = path.replaceAll(RegExp(r'/+$'), '');
    }

    return path.substring(1);
  }
}
