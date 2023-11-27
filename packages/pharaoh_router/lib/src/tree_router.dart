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
    if (!config.caseSensitive) path = path.toLowerCase();

    Node root = getMethodNode(method);

    for (int i = 0; i < path.length; i++) {
      String char = path[i];

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

  Node? search(HTTPMethod method, String path) {
    if (!config.caseSensitive) path = path.toLowerCase();
    Node rootNode = getMethodNode(method);

    Map<String, String> _pathParams = {};

    String route = path;
    for (int i = 0; i < route.length; i++) {
      final char = route[i];

      final hasChild = rootNode.hasChild(char);
      if (hasChild) {
        rootNode = rootNode.getChild(char);
      } else {
        final anyParametrics =
            rootNode.children.values.whereType<ParametricNode>();
        if (anyParametrics.isEmpty) return null;

        for (final paramNode in anyParametrics) {
          final val = getPathParameter(path, at: i);
          final valLength = val.length;
          final nextCharIndex = valLength + i;
          final endOfPath = nextCharIndex >= path.length;

          if (!endOfPath) {
            final nextChar = path[nextCharIndex];
            if (!paramNode.hasChild(nextChar)) continue;
          }

          _pathParams[paramNode.name] = val;
          rootNode = paramNode;
          i = nextCharIndex - 1;
          break;
        }
      }
    }

    print(_pathParams);
    return rootNode.terminal ? rootNode : null;
  }
}

void main() async {
  final radixTree = RadixRouter();

  radixTree.insert(HTTPMethod.GET, '/foo/bar');
  radixTree.insert(HTTPMethod.GET, '/chima/bar');
  radixTree.insert(HTTPMethod.GET, '/foo/bar/home');
  radixTree.insert(HTTPMethod.GET, '/a/:user/c');
  radixTree.insert(HTTPMethod.GET, '/foo/:param1-:param2');
  radixTree.insert(HTTPMethod.GET, '/foo/:user1/:location');

  radixTree.printTree();

  final node = radixTree.search(HTTPMethod.GET, '/foo/bar/home');
  print(node);

  // case insensitive with multiple mixed-case params within same slash couple
  final node2 = radixTree.search(HTTPMethod.GET, '/FOO/My-bAR');
  print(node2);

  // case insensitive with multiple mixed-case params
  final node3 = radixTree.search(HTTPMethod.GET, '/FOO/My/bAR');
  print(node3);
}
