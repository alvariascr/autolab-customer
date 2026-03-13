import 'dart:async';

import 'package:autolab_core/autolab_core.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeCrashReporter implements CrashReporter {
  Object? capturedError;
  StackTrace? capturedStackTrace;
  String? capturedReason;

  @override
  Future<void> log(String message) async {}

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    capturedError = error;
    capturedStackTrace = stackTrace;
    capturedReason = reason;
  }
}

void main() {
  group('GlobalErrorHandler', () {
    test('handle devuelve Failure y reporta error', () async {
      final crashReporter = FakeCrashReporter();
      final handler = GlobalErrorHandler(
        logger: AppLogger(),
        exceptionMapper: const ExceptionMapper(),
        crashReporter: crashReporter,
      );

      final error = TimeoutException('timeout');
      final stackTrace = StackTrace.current;

      final failure = handler.handle(error, stackTrace);

      expect(failure, isA<TimeoutFailure>());

      await Future<void>.delayed(Duration.zero);

      expect(crashReporter.capturedError, error);
      expect(crashReporter.capturedReason, failure.message);
    });
  });
}
