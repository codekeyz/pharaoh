import '../tree/node.dart';
import '../tree/tree.dart';
import 'utils.dart';

SingleParameterDefn _singleParamDefn(RegExpMatch m) => SingleParameterDefn._(
      m.group(2)!,
      prefix: m.group(1)?.nullIfEmpty,
      suffix: m.group(3)?.nullIfEmpty,
    );

ParameterDefinition buildParamDefinition(String part) {
  if (closeDoorParametricRegex.hasMatch(part)) {
    throw ArgumentError.value(
        part, null, 'Parameter definition is invalid. Close door neighbors');
  }

  final matches = parametricDefnsRegex.allMatches(part);
  if (matches.isEmpty) {
    throw ArgumentError.value(part, null, 'Parameter definition is invalid');
  }

  if (matches.length == 1) {
    return _singleParamDefn(matches.first);
  }

  return CompositeParameterDefinition._(matches.map(_singleParamDefn));
}

abstract class ParameterDefinition implements HandlerStore {
  String get name;

  String get templateStr;

  RegExp get template;

  String get key;

  bool get terminal;

  void resolveParams(String pattern, Map<String, dynamic> collector);
}

class SingleParameterDefn extends ParameterDefinition with HandlerStoreMixin {
  @override
  final String name;

  final String? prefix;
  final String? suffix;

  @override
  final String templateStr;

  @override
  late final RegExp template;

  @override
  String get key => 'prefix=$prefix&suffix=$suffix&terminal=$terminal';

  bool _terminal;

  @override
  bool get terminal => _terminal;

  SingleParameterDefn._(
    this.name, {
    this.prefix,
    this.suffix,
  })  : templateStr = buildTemplateString(
          name: name,
          prefix: prefix,
          suffix: suffix,
        ),
        _terminal = false {
    template = buildRegexFromTemplate(templateStr);
  }

  bool matches(String pattern) => template.hasMatch(pattern);

  @override
  void resolveParams(final String pattern, Map<String, dynamic> collector) {
    final match = template.firstMatch(pattern);
    if (match == null) return;

    collector[name] = match.namedGroup(name);
  }

  @override
  void addRoute<T>(HTTPMethod method, IndexedValue<T> handler) {
    super.addRoute(method, handler);
    _terminal = true;
  }
}

class CompositeParameterDefinition extends ParameterDefinition
    implements HandlerStore {
  final Iterable<SingleParameterDefn> parts;
  final SingleParameterDefn _maybeTerminalPart;

  CompositeParameterDefinition._(this.parts) : _maybeTerminalPart = parts.last;

  @override
  String get templateStr => parts.map((e) => e.templateStr).join();

  @override
  String get name => parts.map((e) => e.name).join('|');

  @override
  String get key => parts.map((e) => e.key).join('|');

  @override
  RegExp get template => buildRegexFromTemplate(templateStr);

  @override
  bool get terminal => _maybeTerminalPart.terminal;

  @override
  void resolveParams(String pattern, Map<String, dynamic> collector) {
    final match = template.firstMatch(pattern);
    if (match == null) return;

    for (final key in match.groupNames) {
      collector[key] = match.namedGroup(key);
    }
  }

  @override
  void addMiddleware<T>(IndexedValue<T> handler) {
    _maybeTerminalPart.addMiddleware(handler);
  }

  @override
  void addRoute<T>(HTTPMethod method, IndexedValue<T> handler) {
    _maybeTerminalPart.addRoute(method, handler);
  }

  @override
  IndexedValue? getHandler(HTTPMethod method) {
    return _maybeTerminalPart.getHandler(method);
  }

  @override
  bool hasMethod(HTTPMethod method) => _maybeTerminalPart.hasMethod(method);

  @override
  Iterable<HTTPMethod> get methods => _maybeTerminalPart.methods;
}
