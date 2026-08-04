import 'package:flutter_test/flutter_test.dart';
import 'package:chhat/services/single_flight_guard.dart';

void main() {
  group('SingleFlightGuard', () {
    test('pehli call allow ho', () {
      final guard = SingleFlightGuard<String>();
      final completer = guard.start('busy');
      expect(completer.isCompleted, false);
    });

    test('pichli call pending ho toh nayi call reject ho (race condition fix)',
        () {
      final guard = SingleFlightGuard<String>();
      guard.start('Pehli request abhi process ho rahi hai, thoda ruko');

      expect(
        () => guard.start('Pehli request abhi process ho rahi hai, thoda ruko'),
        throwsA(isA<Exception>()),
      );
    });

    test('pichli call complete ho jaye toh nayi call allow ho', () {
      final guard = SingleFlightGuard<String>();
      final first = guard.start('busy');
      first.complete('done');

      final second = guard.start('busy');
      expect(second.isCompleted, false);
    });

    test(
        'pichli call error se complete ho jaye (jaise timeout) toh nayi call allow ho',
        () {
      final guard = SingleFlightGuard<String>();
      final first = guard.start('busy');
      first.future
          .catchError((_) => ''); // unhandled error warning avoid karne ke liye
      first.completeError(Exception('timeout'));

      final second = guard.start('busy');
      expect(second.isCompleted, false);
    });
  });
}
