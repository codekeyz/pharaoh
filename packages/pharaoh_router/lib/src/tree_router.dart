import 'package:pharaoh/pharaoh.dart';
import 'tree_node.dart';
import 'tree_utils.dart';

class RadixRouterConfig {
  final bool caseSensitive;

  const RadixRouterConfig({
    this.caseSensitive = false,
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

  void insert(HTTPMethod method, String path) {
    Node root = getMethodNode(method);

    for (int i = 0; i < path.length; i++) {
      String char = path[i];
      if (!config.caseSensitive) char = char.toLowerCase();

      /// checking early on to know if the we're iterating
      /// on the start of a parametric route. If it's true, we need to construct
      /// the actual key. which will be :alphanumeric-until-symbol and then
      /// we increment the current Index with the length of the resolved key.
      final hasParam = isParametric(path.substring(i));
      if (hasParam) {
        final paramName = getPathParameter(path.substring(i + 1));
        char += paramName;
        i += paramName.length;
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

  Node? lookup(HTTPMethod method, String path, {bool debug = false}) {
    Node rootNode = getMethodNode(method);

    if (debug) {
      print('------------- Finding node for $path -------------');
    }

    Map<String, String> resolvedParams = {};

    String route = path;
    for (int i = 0; i < route.length; i++) {
      String char = route[i];
      if (!config.caseSensitive) char = char.toLowerCase();

      final hasChild = rootNode.hasChild(char);

      if (hasChild) {
        rootNode = rootNode.getChild(char);
        if (debug) {
          print('We found node for $char');
        }
      } else {
        final anyParametrics =
            rootNode.children.values.whereType<ParametricNode>();
        if (anyParametrics.isEmpty) return null;

        for (final paramNode in anyParametrics) {
          final currentPath = path.substring(i);
          String val = getPathParameter(currentPath);

          /// If there are any symbols in the current path segment,
          /// we need to be sure the current node doesn't have it as a child.
          ///
          /// we do find that the current node has it as a child, then,
          /// resolved parameter will be everything until that special character.
          final indexedSymbols = extractIndexedSymbols(currentPath);
          if (indexedSymbols.isNotEmpty) {
            for (final sym in indexedSymbols) {
              final symIndex = sym.index;
              final afterSymbol = symIndex + 1;
              final nextCharactorAfterSymbol =
                  currentPath.substring(afterSymbol)[0];

              final hasValidNodeAfterAssumedParametricValue =
                  paramNode.hasChild(sym.char) &&
                      paramNode
                          .getChild(sym.char)
                          .hasChild(nextCharactorAfterSymbol);

              if (debug) {
                print(
                    'Char after ${sym.char}: ---> $nextCharactorAfterSymbol ${hasValidNodeAfterAssumedParametricValue ? 'found a node ✅' : 'found no node'}');
              }

              if (hasValidNodeAfterAssumedParametricValue) {
                val = currentPath.substring(0, sym.index);
                break;
              }
            }
          }

          final nextCharIndex = val.length + i;
          final endOfPath = nextCharIndex >= path.length;

          if (!endOfPath) {
            final nextChar = path[nextCharIndex];
            if (!paramNode.hasChild(nextChar)) continue;
          }
          char = val;

          if (debug) {
            print('We found parametric for $char');
          }

          resolvedParams[paramNode.name] = char;
          rootNode = paramNode;
          i = nextCharIndex - 1;
          break;
        }
      }
    }

    if (debug) {
      print('\n');
    }

    if (!rootNode.terminal) return null;
    return rootNode..value = resolvedParams;
  }
}
