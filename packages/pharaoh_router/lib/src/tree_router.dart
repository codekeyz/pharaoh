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
    return _nodeMap[method] = Node();
  }

  void on(HTTPMethod method, String path) {
    Node root = getMethodNode(method);

    for (int i = 0; i < path.length; i++) {
      String char = path[i];
      if (!config.caseSensitive) char = char.toLowerCase();
      final currentpart = path.substring(i);

      /// checking early on to know if the we're iterating
      /// on the start of a parametric or regexeric route.
      ///
      /// If it's true, we need to construct the actual key.
      final hasParam = isParametric(currentpart);
      final hasRegex = isRegexeric(currentpart);

      if (hasParam) {
        final paramName = getPathParameter(path.substring(i + 1));
        char += paramName;
        i += paramName.length;
      } else if (hasRegex) {
        final closingAt = getClosingParenthesisPosition(currentpart, 0);
        final regexStr = currentpart.substring(1, closingAt + 1);
        char += regexStr;
        i += regexStr.length;
      }

      var child = root.children[char];
      if (child == null) {
        if (hasParam) {
          final name = getPathParameter(char.substring(1));
          child = ParametricNode(name);
        } else {
          child = Node();
        }
      }

      root = root.children[char] = child;
    }
    root.terminal = true;
  }

  void printTree() {
    _nodeMap.forEach((key, value) => _printNode(value, '${key.name} '));
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
    return path;
  }

  Node? lookup(HTTPMethod method, String path, {bool debug = false}) {
    Node rootNode = getMethodNode(method);
    String route = cleanPath(path);

    Map<String, String> resolvedParams = {};

    final debugLog = StringBuffer("\n");

    if (debug) {
      debugLog.writeln(
          '------------- Finding node for ${method.name} $route -------------');
    }

    finderLoop:
    for (int i = 0; i < route.length; i++) {
      String char = route[i];
      if (!config.caseSensitive) char = char.toLowerCase();

      final hasChild = rootNode.hasChild(char);
      if (hasChild) {
        rootNode = rootNode.getChild(char);
        if (debug) {
          debugLog
              .writeln('- Found Static for             ->              $char');
        }
      } else {
        switch (rootNode.runtimeType) {
          case ParametricNode:
            debugLog.writeln(
                'Special case unhandled: We should a parametric Node here');
            break finderLoop;
          case Node:
            debugLog.writeln('- Current Node does not have child for $char');
            final parametrics = rootNode.paramNodes;
            if (parametrics.isEmpty) return null;
            debugLog
                .writeln("- But it has ${parametrics.length} parametric node");

            final resolve = getParametricNode(path.substring(i), parametrics);
            if (resolve == null) break finderLoop;

            final resolvedNode = resolve.node;

            if (resolvedNode is ParametricNode) {
              final param = resolve.param;
              debugLog.writeln(
                  "- Then we found ParametricNode with ${resolvedNode.name}:$param");

              resolvedParams[resolvedNode.name] = param;
              final formerIndex = i;
              i += (param.length - 1);

              debugLog.writeln(
                  "- Current index is now moved from $formerIndex  to $i");
            }
            rootNode = resolvedNode;
            break;
        }

        // debugLog.writeln(
        //     '- Found Node($node) ${value.param} for     ->              $char');
      }
    }

    if (debug) {
      print(debugLog);
    }

    if (!rootNode.terminal) return null;
    return rootNode..value = resolvedParams;
  }
}

typedef ParamValueAndNode = ({String param, Node node});

ParamValueAndNode? getParametricNode(
  String path,
  List<ParametricNode> paramNodes,
) {
  final indexedSymbols = extractIndexedSymbols(path);
  if (indexedSymbols.isEmpty && paramNodes.length == 1) {
    return (param: path, node: paramNodes.first);
  }

  for (final node in paramNodes) {
    String param = '';
    for (final sym in indexedSymbols) {
      final hasChild = node.hasChild(sym.char);
      if (!hasChild) break;

      param += path.substring(0, sym.index);
      return (node: node, param: param);
    }
  }
  return null;
}
