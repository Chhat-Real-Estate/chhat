import 'dart:async';

/// Ensures only one async operation of a kind is "in flight" at a time.
/// [start] naya operation shuru karta hai — agar pichla operation abhi
/// complete nahi hua, [Exception] throw karta hai (WebView/network se
/// independent, isliye standalone unit-test ho sakta hai).
class SingleFlightGuard<T> {
  Completer<T>? _completer;

  Completer<T> start(String busyMessage) {
    if (_completer != null && !_completer!.isCompleted) {
      throw Exception(busyMessage);
    }
    final completer = Completer<T>();
    _completer = completer;
    return completer;
  }
}
