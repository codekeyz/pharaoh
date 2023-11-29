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

  void addRoute(HTTPMethod method, String path, {bool debug = false}) {
    path = cleanPath(path);
    Node root = getMethodNode(method);

    void log(String message) {
      if (!debug) return;
      print('$message\n');
    }

    log('Building node tree for --------- $path --------------');

    final parts = path.split('/');
    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      final parametric = isParametric(part);
      final isLastPart = i == (parts.length - 1);

      final key = parametric ? ':' : part;

      void assignNewRoot(Node node) {
        root = root.addChildAndReturn(key, node);
        log('Root node is now ${node.name}');
      }

      log('Search node for $part');

      var child = root.children[part];
      if (child == null) {
        log('Found no node for $part');

        if (!parametric) {
          child = StaticNode(key);
          assignNewRoot(child);
        } else {
          log('$part is parametric');

          final paramNode = root.paramNode;
          if (paramNode == null) {
            log('No existing parametric on ${root.name} yet so we create one');

            assignNewRoot(ParametricNode.fromPath(part));
            continue;
          }

          paramNode.addNewDefinition(part);

          log('Found & updated definitions for ${paramNode.name}');
          assignNewRoot(paramNode);
        }
      } else {
        assignNewRoot(child);
      }
    }

    root.terminal = true;
  }

  // void on(HTTPMethod method, String path) {
  //   Node root = getMethodNode(method);

  //   for (int i = 0; i < path.length; i++) {
  //     String char = path[i];
  //     if (!config.caseSensitive) char = char.toLowerCase();
  //     final currentpart = path.substring(i);

  //     /// checking early on to know if the we're iterating
  //     /// on the start of a parametric or regexeric route.
  //     ///
  //     /// If it's true, we need to construct the actual key.
  //     final hasParam = isParametric(currentpart);
  //     final hasRegex = isRegexeric(currentpart);

  //     if (hasParam) {
  //       final paramName = getPathParameter(path.substring(i + 1));
  //       char += paramName;
  //       i += paramName.length;
  //     } else if (hasRegex) {
  //       final closingAt = getClosingParenthesisPosition(currentpart, 0);
  //       final regexStr = currentpart.substring(1, closingAt + 1);
  //       char += regexStr;
  //       i += regexStr.length;
  //     }

  //     var child = root.children[char];
  //     if (child == null) {
  //       if (hasParam) {
  //         final name = getPathParameter(char.substring(1));
  //         child = ParametricNode(name);
  //       } else {
  //         child = StaticNode(char);
  //       }
  //     }

  //     root = root.children[char] = child;
  //   }
  //   root.terminal = true;
  // }

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
