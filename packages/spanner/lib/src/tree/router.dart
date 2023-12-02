import 'package:pharaoh/pharaoh.dart';
import '../helpers/parametric.dart';
import 'node.dart';

class RouterConfig {
  final bool caseSensitive;
  final bool ignoreTrailingSlash;
  final bool ignoreDuplicateSlashes;
  final String basePath;

  const RouterConfig({
    this.caseSensitive = true,
    this.ignoreTrailingSlash = true,
    this.ignoreDuplicateSlashes = true,
    this.basePath = '/',
  });
}

class Router {
  final RouterConfig config;
  final Map<HTTPMethod, Node> _nodeMap = {};

  Router({
    this.config = const RouterConfig(),
  });

  Node getMethodNode(HTTPMethod method) {
    var node = _nodeMap[method];
    if (node != null) return node;
    return _nodeMap[method] = StaticNode(config.basePath);
  }

  void on(
    HTTPMethod method,
    String path,
    RouteHandler handler, {
    bool debug = false,
  }) {
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

      final key = part.isParametric
          ? '<:>'
          : part.isWildCard
              ? '<*>'
              : part;
      final isLastPart = i == (parts.length - 1);

      void assignNewRoot(Node node) {
        root = root.addChildAndReturn(key, node);
        devlog('- Root node is now ${node.name}');
      }

      var child = root.children[part];
      if (child != null) {
        devlog('- Found static node for $part');
        assignNewRoot(child);
      } else {
        if (part.isStatic) {
          child = StaticNode(key);
          assignNewRoot(child);
          continue;
        } else if (part.isWildCard) {
          if (!isLastPart) {
            throw ArgumentError.value(path, null,
                'Route definition is not valid. Wildcard must be the end of the route');
          }

          child = WildcardNode();
          assignNewRoot(child);
          continue;
        }

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

      final hasChild = rootNode.hasChild(routePart);
      final isEndOfPath = i == (parts.length - 1);

      void useWildcard(WildcardNode wildcard) {
        resolvedParams['*'] = parts.sublist(i).join('/');
        rootNode = wildcard;
      }

      if (hasChild) {
        rootNode = rootNode.getChild(routePart);
        devlog('- Found Static for             ->              $routePart');
      } else {
        final paramNode = rootNode.paramNode;
        if (paramNode == null) {
          devlog('x Found no static node for part       ->         $routePart');
          devlog('x Route is not registered             ->         $route');

          final wc = rootNode.wildcardNode;
          if (wc != null) {
            useWildcard(wc);
            break;
          }
          return null;
        }

        final hasChild = paramNode.hasChild(routePart);
        if (hasChild) {
          devlog('- Found Static for             ->              $routePart');
          rootNode = paramNode.getChild(routePart);
          continue;
        }

        devlog(
            '- Finding Defn for $routePart        -> terminal?    $isEndOfPath');

        final paramDefn = paramNode.findMatchingDefinition(routePart,
            shouldBeTerminal: isEndOfPath);

        devlog('    * parametric defn:         ${paramDefn.toString()}');

        if (paramDefn == null) {
          devlog('x Found no defn for route part      ->         $routePart');
          devlog('x Route is not registered             ->         $route');

          final wc = rootNode.wildcardNode;
          if (wc != null) useWildcard(wc);
          break;
        }

        devlog('- Found defn for route part    ->              $routePart');

        final params = paramDefn.resolveParams(currPart);
        resolvedParams.addAll(params);
        rootNode = paramNode;

        if (paramDefn.terminal) {
          rootNode.terminal = true;
          break;
        }
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
    if (node.terminal) print('$prefix*');
    node.children.forEach(
      (char, node) => _printNode(node, '$prefix$char -> '),
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
