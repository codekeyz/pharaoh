import '../tree/node.dart';
import '../tree/tree.dart';
import 'utils.dart';

typedef ParamAndValue = ({String name, String? value});

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

  String get key;

  bool get terminal;

  bool matches(String route, {bool caseSensitive = false});

  void resolveParams(String pattern, List<ParamAndValue> collector);
}

class SingleParameterDefn extends ParameterDefinition with HandlerStoreMixin {
  @override
  final String name;

  final String? prefix;
  final String? suffix;

  @override
  final String templateStr;

  @override
  String get key => 'prefix=$prefix&suffix=$suffix';

  bool _terminal;

  @override
  bool get terminal => _terminal;

  @override
  bool matches(String route, {bool caseSensitive = false}) {
    final match = matchPattern(route, prefix ?? '', suffix ?? '');
    return match != null;
  }

  SingleParameterDefn._(
    this.name, {
    this.prefix,
    this.suffix,
  })  : templateStr =
            buildTemplateString(name: name, prefix: prefix, suffix: suffix),
        _terminal = false;

  @override
  void resolveParams(final String pattern, List<ParamAndValue> collector) {
    collector.add(
      (
        name: name,
        value: matchPattern(pattern, prefix ?? "", suffix ?? ""),
      ),
    );
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

  RegExp get _template => buildRegexFromTemplate(templateStr);

  @override
  bool get terminal => _maybeTerminalPart.terminal;

  @override
  bool matches(String route, {bool caseSensitive = false}) =>
      _template.hasMatch(route);

  @override
  void resolveParams(String pattern, List<ParamAndValue> collector) {
    final match = _template.firstMatch(pattern);
    if (match == null) return;

    for (final key in match.groupNames) {
      collector.add((name: key, value: match.namedGroup(key)));
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
  void offsetIndex(int index) => _maybeTerminalPart.offsetIndex(index);

  @override
  IndexedValue? getHandler(HTTPMethod method) {
    return _maybeTerminalPart.getHandler(method);
  }

  @override
  bool hasMethod(HTTPMethod method) => _maybeTerminalPart.hasMethod(method);

  @override
  Iterable<HTTPMethod> get methods => _maybeTerminalPart.methods;
}
