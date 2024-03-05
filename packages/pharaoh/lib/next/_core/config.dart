part of '../core.dart';

DotEnv? _env;

T env<T extends Object>(String name, T defaultValue) {
  _env ??= DotEnv(quiet: true, includePlatformEnvironment: true)..load();
  final strVal = _env![name];
  if (strVal == null) return defaultValue;

  final parsedVal = switch (T) {
    const (String) => strVal,
    const (int) => int.parse(strVal),
    const (num) => num.parse(strVal),
    const (bool) => bool.parse(strVal),
    const (double) => double.parse(strVal),
    const (List<String>) => jsonDecode(strVal),
    _ => throw ArgumentError.value(
        T, null, 'Unsupported Type used in `env` call.'),
  };
  return parsedVal as T;
}

extension ConfigExtension on Map<String, dynamic> {
  T getValue<T>(String name, {T? defaultValue, bool allowEmpty = false}) {
    final value = this[name] ?? defaultValue;
    if (value is! T) {
      throw ArgumentError.value(
          value, null, 'Invalid value provided for $name');
    }
    if (value != null && value.toString().trim().isEmpty && !allowEmpty) {
      throw ArgumentError.value(
          value, null, 'Empty value not allowed for $name');
    }
    return value;
  }
}

class AppConfig {
  final String name;
  final String environment;
  final bool isDebug;
  final String timezone;
  final String locale;
  final String key;
  final int? _port;
  final String? _url;

  Uri get _uri {
    final uri = Uri.parse(_url!);
    return _port == null ? uri : uri.replace(port: _port);
  }

  int get port => _uri.port;

  String get url => _uri.toString();

  const AppConfig({
    required this.name,
    required this.environment,
    required this.isDebug,
    required this.key,
    this.timezone = 'UTC',
    this.locale = 'en',
    int? port,
    String? url,
  })  : _port = port,
        _url = url;
}
