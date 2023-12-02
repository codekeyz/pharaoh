import 'dart:async';

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

          final defn = ParameterDefinition.from(part, terminal: isLastPart);
          if (isLastPart) defn.handler = handler;

          assignNewRoot(ParametricNode(defn));
          continue;
        }

        paramNode.addNewDefinition(routePart, terminal: isLastPart);
        print('I was here with $routePart');

        assignNewRoot(paramNode);
      }
    }

    /// parametric nodes being terminal is determined
    /// by the exact definition that matched
    if (root is StaticNode) {
      (root as StaticNode)
        ..addHandler(handler)
        ..terminal = true;
    }

    if (debug) print(debugLog);
  }

  FutureOr<Node?> lookup(
    HTTPMethod method,
    String path, {
    bool debug = false,
  }) async {
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

  FutureOr<HandlerResult?> resolve(Request req, Response res) async {
    Node rootNode = getMethodNode(req.method);
    String route = _cleanPath(req.path);

    Map<String, dynamic> resolvedParams = {};

    HandlerResult reqRes = (canNext: true, reqRes: (req: req, res: res));
    Future<bool> executeAndCheckCanProceed(List<RouteHandler> hdlrs) async {
      if (hdlrs.isEmpty) return true;

      for (final hdler in hdlrs) {
        reqRes = await executeHandler(reqRes.reqRes, resolvedParams, hdler);
        if (!reqRes.canNext) break;
      }

      return reqRes.canNext;
    }

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
        final child = rootNode.getChild(routePart) as StaticNode;
        rootNode = child;

        /// execution block
        final canProceed = await executeAndCheckCanProceed(child.handlers);
        if (!canProceed) break;
      } else {
        final paramNode = rootNode.paramNode;
        if (paramNode == null) {
          final wc = rootNode.wildcardNode;
          if (wc != null) {
            useWildcard(wc);
            break;
          }
          return null;
        }

        final hasChild = paramNode.hasChild(routePart);
        if (hasChild) {
          rootNode = paramNode.getChild(routePart);

          /// execution block
          final canProceed = await executeAndCheckCanProceed(
              (rootNode as StaticNode).handlers);
          if (!canProceed) break;
          continue;
        }

        final paramDefn = paramNode.findMatchingDefinition(routePart,
            shouldBeTerminal: isEndOfPath);

        if (paramDefn == null) {
          final wc = rootNode.wildcardNode;
          if (wc != null) useWildcard(wc);
          break;
        }

        final params = paramDefn.resolveParams(currPart);
        resolvedParams.addAll(params);
        rootNode = paramNode;

        /// execution block
        final hdler = paramDefn.handler;
        if (hdler != null) {
          final canProceed = await executeAndCheckCanProceed([hdler]);
          if (!canProceed) break;
        }

        if (paramDefn.terminal) {
          rootNode.terminal = true;
          break;
        }
      }
    }

    if (!rootNode.terminal) return null;

    return reqRes;
  }

  Future<HandlerResult> executeHandler(
    ReqRes reqRes,
    Map<String, dynamic> params,
    RouteHandler handler,
  ) async {
    for (final entry in params.entries) {
      reqRes.req.setParams(entry.key, entry.value);
    }
    return handler.execute(reqRes);
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
