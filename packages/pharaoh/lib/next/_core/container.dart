import 'package:get_it/get_it.dart';

final GetIt _getIt = GetIt.instance;

T instanceFromRegistry<T extends Object>({Type? type}) {
  type ??= T;
  try {
    return _getIt.get(type: type) as T;
  } catch (_) {
    throw Exception('Dependency not found in registry: $type');
  }
}

T registerSingleton<T extends Object>(T instance) {
  return _getIt.registerSingleton<T>(instance);
}

bool isRegistered<T extends Object>() => _getIt.isRegistered<T>();
