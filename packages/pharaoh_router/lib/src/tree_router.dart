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

    outer:
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
        final paramNodes = rootNode.children.values.whereType<ParametricNode>();
        if (paramNodes.isEmpty) return null;

        if (debug) {
          debugLog.writeln(
              '- Found Parametric (${paramNodes.length}) for     ->              $char');
        }

        /// special case when we have only one parametric route in this node
        if (paramNodes.hasOnlyOneTerminal) {
          final paramNode = paramNodes.first;
          final val = path.substring(i, path.length);
          char = val;
          resolvedParams[paramNode.name] = char;
          rootNode = paramNode;

          if (debug) {
            debugLog.writeln(
                '  and is a terminal so end.    ->              $char   ✅');
          }
          break;
        }

        parametericFind:
        for (final paramNode in paramNodes) {
          if (debug) {
            debugLog.writeln('     *maybe?    :${paramNode.name}');
          }
          final currentPath = path.substring(i);
          String val = getPathParameter(currentPath);

          /// If there are any symbols in the current path segment,
          /// we need to be sure the current node doesn't have it as a child.
          ///
          /// we do find that the current node has it as a child, then,
          /// resolved parameter will be everything until that special character.
          final indexedSymbols = extractIndexedSymbols(currentPath);
          if (debug) {
            debugLog.writeln(
                '     *symbols:  ${indexedSymbols.map((e) => e.char).join(', ')}');
          }

          /// if we have symbols in the current path segment
          /// we need to verify that what we're capturing is the
          /// actual parameter.
          ///
          /// If we find no static nodes for the symbols,
          /// the whole string is written off as a parameter.
          ///
          /// eg: user-name/ -> will give us user as parameter. But then we have
          /// - and / as symbols.
          if (indexedSymbols.isNotEmpty) {
            for (final sym in indexedSymbols) {
              final symIndex = sym.index;
              final charAfterSymbol = symIndex + 1;
              final symbolPath = path.substring(charAfterSymbol + 1);
              final nextCharacter = symbolPath[0];

              final isActualNodeToUse = paramNode.hasChild(sym.char) &&
                  paramNode.getChild(sym.char).hasChild(nextCharacter);

              if (isActualNodeToUse) {
                if (debug) {
                  debugLog.writeln(
                      "- Found Static for             ->            _(${sym.char})_ and it's next $nextCharacter");
                }

                i += charAfterSymbol;
                rootNode = paramNode.getChild(sym.char).getChild(nextCharacter);
                resolvedParams[paramNode.name] = val;
                break parametericFind;
              } else {
                val = currentPath.substring(0, symIndex + 1);
              }
            }
          }

          final nextCharIndex = val.length + i;
          final endOfPath = nextCharIndex >= path.length;
          if (!endOfPath) {
            final nextChar = path[nextCharIndex];
            if (!paramNode.hasChild(nextChar)) continue;
          }

          if (!paramNode.terminal) continue;

          char = val;
          resolvedParams[paramNode.name] = char;
          rootNode = paramNode;
          i = nextCharIndex - 1;

          if (debug) {
            debugLog.writeln(
                '- Node :${paramNode.name} works for ->        $char  ✅');
          }
          break;
        }
      }
    }

    if (debug) {
      print(debugLog);
    }

    if (!rootNode.terminal) return null;
    return rootNode..value = resolvedParams;
  }
}
