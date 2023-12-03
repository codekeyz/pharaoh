import 'dart:async';

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

class Router {
  final RouterConfig config;
  final Node _root = StaticNode('/');

  Router({
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

      final key = part.isParametric
          ? '<:>'
          : part.isWildCard
              ? '<*>'
              : part;
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
        paramNode.addNewDefinition(defn);

        assignNewRoot(paramNode);
      }
    }

    /// parametric nodes being terminal is determined its definitions
    if (root is StaticNode || root is WildcardNode) {
      (root as StaticNode)
        ..addAction(action)
        ..terminal = true;
    }
  }

  Future<RouteResult?> find(
    Request req,
    Response res, {
    bool debug = false,
  }) async {
    return lookup(req.method, req.path);
  }

  RouteResult? lookup(HTTPMethod method, String path, {bool debug = false}) {
    Node rootNode = _root;
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
      final isLastPart = i == (parts.length - 1);

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
            '- Finding Defn for $routePart        -> terminal?    $isLastPart');

        final paramDefn = paramNode.findMatchingDefinition(routePart,
            shouldBeTerminal: isLastPart);

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

        if (isLastPart && paramDefn.terminal) {
          rootNode.terminal = true;
          return RouteResult(resolvedParams, paramDefn.getActions(method));
        }
      }
    }

    if (debug) print(debugLog);

    if (!rootNode.terminal) return null;

    final List<RouteHandler> handlers = switch (rootNode.runtimeType) {
      StaticNode => (rootNode as StaticNode).getActions(method),
      WildcardNode => (rootNode as WildcardNode).getActions(method),
      _ => [],
    };

    return RouteResult(resolvedParams, handlers);
  }

  FutureOr<HandlerResult?> resolve(Request req, Response res) async {
    Node rootNode = _root;
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
        // final canProceed = await executeAndCheckCanProceed(child.handlers);
        // if (!canProceed) break;
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
          // final canProceed = await executeAndCheckCanProceed(
          //     (rootNode as StaticNode).handlers);
          // if (!canProceed) break;
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
        // final hdler = paramDefn.handler;
        // if (hdler != null) {
        //   final canProceed = await executeAndCheckCanProceed([hdler]);
        //   if (!canProceed) break;
        // }

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
    _printNode(_root, '${_root.name} ');
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

class RouteResult {
  final Map<String, dynamic> params;
  final List<RouteHandler> handlers;

  const RouteResult(this.params, this.handlers);
}
