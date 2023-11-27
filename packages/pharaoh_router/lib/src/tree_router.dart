import 'package:pharaoh/pharaoh.dart';
import 'tree_node.dart';
import 'tree_utils.dart';

class RadixTree {
  final Map<HTTPMethod, Node> _nodeMap = {};

  Node getMethodNode(HTTPMethod method) {
    var node = _nodeMap[method];
    if (node != null) return node;
    return _nodeMap[method] = Node();
  }

  void insert(HTTPMethod method, String path) {
    Node root = getMethodNode(method);

    for (int i = 0; i < path.length; i++) {
      var char = path[i];
      var child = root.children[char];
      if (child == null) {
        final p_ = path.substring(i);
        if (isParametric(p_)) {
          final paramName = getPathParameter(p_.substring(1));
          child = ParametricNode(paramName);
          char += paramName;
          i += paramName.length;
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
    Node rootNode = getMethodNode(method);

    Map<String, String> _pathParams = {};

    String route = path;
    for (int i = 0; i < route.length; i++) {
      final char = route[i];

      final hasChild = rootNode.hasChild(char);
      if (hasChild) {
        rootNode = rootNode.getChild(char);
        print('We have a node for $char');
      } else {
        final anyParametrics =
            rootNode.children.values.whereType<ParametricNode>();
        if (anyParametrics.isEmpty) return null;

        for (final paramNode in anyParametrics) {
          final val = getPathParameter(path, at: i);
          final valLength = val.length;
          final nextCharIndex = valLength + i;
          if (!paramNode.hasChild(path[nextCharIndex])) continue;
          _pathParams[paramNode.name] = val;
          rootNode = paramNode;

          i = nextCharIndex - 1;
          print('For $char to $val, we found parametric');
          break;
        }
      }
    }

    print(_pathParams);
    return rootNode.terminal ? rootNode : null;
  }
}

//  final paramNodes =
//       if (paramNodes.isNotEmpty) {
//         final paramNode = paramNodes.first;
//         final param = getPathParameter(path.substring(i));
//         _pathParams[paramNode.param] = param;
//         route = path.substring(param.length + i);
//         i = 0;
//         rootNode = paramNode;
//       }

void main() {
  final radixTree = RadixTree();

  radixTree.insert(HTTPMethod.GET, '/foo/bar');
  radixTree.insert(HTTPMethod.GET, '/chima/bar');
  radixTree.insert(HTTPMethod.GET, '/foo/bar/home');
  // radixTree.insert(HTTPMethod.GET, '/a/:b/c');
  radixTree.insert(HTTPMethod.GET, '/a/:user/c');

  radixTree.printTree();

  // final node = radixTree.search(HTTPMethod.GET, '/foo/bar/home');
  // print(node);

  final node2 = radixTree.search(HTTPMethod.GET, '/a/chima/c');
  print(node2);
}
