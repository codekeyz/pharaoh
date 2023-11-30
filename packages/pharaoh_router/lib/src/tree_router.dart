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

          assignNewRoot(ParametricNode.fromPath(part, terminal: isLastPart));
          continue;
        }

        paramNode.addNewDefinition(part, terminal: isLastPart);

        devlog('- Found & updated definitions to ${paramNode.name}');
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
        if (paramNode == null) {
          devlog('x Found no static node for part       ->         $currPart');
          devlog('x Route is not registered             ->         $route');
          break;
        }

        final hasChild = paramNode.hasChild(currPart);
        if (hasChild) {
          devlog('- Found Static for             ->              $currPart');
          rootNode = paramNode.getChild(currPart);
          continue;
        }

        devlog(
            '- Finding Defn for $currPart        -> terminal?    $shouldBeTerminal');

        final paramDefn = findMatchingParametricDefinition(
          paramNode,
          currPart,
          terminal: isEndOfPath,
        );

        devlog('    * parametric defn:         ${paramDefn.toString()}');

        if (paramDefn == null) {
          /// TODO(codekeyz) route not found because either you have a
          /// static child or fall into the parametric zone.
          /// If you fall here, and we find no definition, then route entry doesn't exist
          devlog('x Found no defn for route part      ->         $currPart');
          devlog('x Route is not registered             ->         $route');
          break;
        }

        devlog('- Found defn for route part    ->              $currPart');

        /// TODO(codekey) this is where we will need to use the [maybeStatic]
        /// props to validate the parameter and accurately resolve the paramValue.
        /// for now, we're just using the entire [currPart] as the value.
        final actualValue = resolveActualParamValue(paramDefn, currPart);
        resolvedParams[paramDefn.name] = actualValue;
        rootNode = paramNode;

        /// we rety on
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

ParametricDefinition? findMatchingParametricDefinition(
  ParametricNode node,
  String pattern, {
  bool terminal = false,
}) {
  final defns = node.definitions;

  ParametricDefinition? result;
  for (final defn in defns) {
    if (terminal != defn.terminal) continue;

    final expectedSuffix = defn.suffix;
    if (expectedSuffix != null) {
      if (!pattern.endsWith(expectedSuffix)) continue;
    }
    result = defn;
    break;
  }

  return result;
}

dynamic resolveActualParamValue(ParametricDefinition defn, String pattern) {
  String actualValue = pattern;
  final suffix = defn.suffix;
  if (suffix != null) {
    if (suffix.length >= pattern.length) return null;
    actualValue = pattern.substring(0, pattern.length - suffix.length);
  }
  return actualValue;
}
