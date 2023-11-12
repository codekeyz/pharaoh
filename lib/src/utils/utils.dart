import 'dart:async';
import 'dart:convert';

String encodeObject(dynamic object) {
  if (object == null) return 'null';
  if (object is Map) return jsonEncode(object);
  if (object is String) return object;
  return object.toString();
}

/// Run [callback] and capture any errors that would otherwise be top-leveled.
///
/// If `this` is called in a non-root error zone, it will just run [callback]
/// and return the result. Otherwise, it will capture any errors using
/// [runZoned] and pass them to [onError].
void catchTopLevelErrors(void Function() callback,
    void Function(dynamic error, StackTrace) onError) {
  if (Zone.current.inSameErrorZone(Zone.root)) {
    return runZonedGuarded(callback, onError);
  } else {
    return callback();
  }
}
