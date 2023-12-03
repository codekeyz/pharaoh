// ignore: depend_on_referenced_packages
import 'package:meta/meta.dart';

import 'package:pharaoh/pharaoh.dart';
import '../route/action.dart';
import '../parametric/definition.dart';
import '../parametric/utils.dart';
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

class Spanner {
  final RouterConfig config;
  final Node _root = StaticNode('/');

  Spanner({
    this.config = const RouterConfig(),
  });

  void on(HTTPMethod method, String path, RouteHandler handler) {
    return on_(path, RouteAction(handler, method: method));
  }

  void on_(String path, RouteAction action) {
    path = _cleanPath(path);
    Node root = _root;

    final parts = path.split('/');
    for (int i = 0; i < parts.length; i++) {
      final String routePart = parts[i];

      String part = routePart;
      if (!config.caseSensitive) part = part.toLowerCase();

      final key = part.isParametric ? '<:>' : part;
      final isLastPart = i == (parts.length - 1);

      void assignNewRoot(Node node) {
        root = root.addChildAndReturn(key, node);
      }

      var child = root.children[part];
      if (child != null) {
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
          final defn =
              ParameterDefinition.from(routePart, terminal: isLastPart);
          if (isLastPart) defn.addAction(action);

          assignNewRoot(ParametricNode(defn));
          continue;
        }

        final defn = ParameterDefinition.from(routePart, terminal: isLastPart);
        if (isLastPart) defn.addAction(action);

        assignNewRoot(paramNode..addNewDefinition(defn));
      }
    }

    /// parametric nodes being terminal is determined its definitions
    if (root is StaticNode || root is WildcardNode) {
      (root as StaticNode)
        ..addAction(action)
        ..terminal = true;
    }
  }

  RouteResult? lookup(HTTPMethod method, String path, {bool debug = false}) {
    Node rootNode = _root;
    String route = _cleanPath(path);

    Map<String, dynamic> resolvedParams = {};
    List<RouteHandler> wildcardHandlers = [];

    final debugLog = StringBuffer("\n");

    void devlog(String message) {
      if (!debug) return;
      debugLog.writeln(message.toLowerCase());
      print(debugLog);
    }

    devlog('Finding node for ---------  ${method.name} $route ------------\n');

    final parts = route.split('/');

    for (int i = 0; i < parts.length; i++) {
      final String currPart = parts[i];

      var routePart = currPart;
      if (!config.caseSensitive) routePart = routePart.toLowerCase();

      final hasChild = rootNode.hasChild(routePart);
      final isLastPart = i == (parts.length - 1);

      final wildcard = rootNode.wildcardNode;
      if (wildcard != null) {
        final handlers = wildcard.getActions(method);
        wildcardHandlers.addAll(handlers);
      }

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
          if (wc == null) return null;

          useWildcard(wc);
          break;
        }

        final hasChild = paramNode.hasChild(routePart);
        if (hasChild) {
          devlog('- Found Static for             ->              $routePart');
          rootNode = paramNode.getChild(routePart);
          continue;
        }

        devlog(
            '- Finding Defn for $routePart        -> terminal?    $isLastPart');

        final paramDefn = paramNode.findMatchingDefinition(
          method,
          routePart,
          shouldBeTerminal: isLastPart,
        );

        devlog('    * parametric defn:         ${paramDefn.toString()}');

        if (paramDefn == null) {
          devlog('x Found no defn for route part      ->         $routePart');
          devlog('x Route is not registered             ->         $route');

          final wc = rootNode.wildcardNode;
          if (wc == null) return null;

          useWildcard(wc);
          break;
        }

        devlog('- Found defn for route part    ->              $routePart');

        final params = paramDefn.resolveParams(currPart);
        resolvedParams.addAll(params);
        rootNode = paramNode;

        if (isLastPart && paramDefn.terminal) {
          rootNode.terminal = true;
          return RouteResult(
            resolvedParams,
            paramDefn.getActions(method),
            actual: paramDefn,
          );
        }
      }
    }

    if (!rootNode.terminal) return null;

    final List<RouteHandler> handlers = switch (rootNode.runtimeType) {
      StaticNode => (rootNode as StaticNode).getActions(method),
      WildcardNode => (rootNode as WildcardNode).getActions(method),
      _ => [],
    };

    return RouteResult(
      resolvedParams,
      [...wildcardHandlers, ...handlers],
      actual: rootNode,
    );
  }

  void printTree() {
    _printNode(_root, '${_root.name} ');
  }

  void _printNode(Node node, String prefix) {
    if (node.terminal) print('$prefix*');
    node.children.forEach(
      (char, node) => _printNode(node, '$prefix$char -> '),
    );
  }

  String _cleanPath(String path) {
    if (!path.startsWith('/')) {
      throw ArgumentError.value(
          path, null, 'Route registration must start with `/`');
    }
    if (config.ignoreDuplicateSlashes) {
      path = path.replaceAll(RegExp(r'/+'), '/');
    }
    if (config.ignoreTrailingSlash) {
      path = path.replaceAll(RegExp(r'/+$'), '');
    }
    return path.substring(1);
  }
}

class RouteResult {
  final Map<String, dynamic> params;
  final List<RouteHandler> handlers;

  @visibleForTesting
  final dynamic actual;

  const RouteResult(
    this.params,
    this.handlers, {
    this.actual,
  });
}
