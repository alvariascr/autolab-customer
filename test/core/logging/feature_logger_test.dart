import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/core/logging/feature_logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAppLogger extends Mock implements AppLogger {}

void main() {
  group('FeatureLogger', () {
    late MockAppLogger appLogger;
    late FeatureLogger featureLogger;

    setUp(() {
      appLogger = MockAppLogger();
      featureLogger = FeatureLogger(appLogger);

      when(() => appLogger.i(any())).thenReturn(null);
      when(
        () => appLogger.w(
          any(),
          error: any(named: 'error'),
          stackTrace: any(named: 'stackTrace'),
        ),
      ).thenReturn(null);
      when(
        () => appLogger.e(
          any(),
          error: any(named: 'error'),
          stackTrace: any(named: 'stackTrace'),
        ),
      ).thenReturn(null);
    });

    test('masks sensitive context values before logging', () {
      featureLogger.info(
        feature: 'auth',
        action: 'login_started',
        context: {
          'email': 'user@example.com',
          'userId': 'user-12345',
          'token': 'secret-token',
          'count': 3,
        },
      );

      final capturedMessage =
          verify(() => appLogger.i(captureAny())).captured.single as String;

      expect(capturedMessage, contains('email=u***@example.com'));
      expect(capturedMessage, contains('userId=use***45'));
      expect(capturedMessage, contains('token=<redacted>'));
      expect(capturedMessage, contains('count=3'));
      expect(capturedMessage, isNot(contains('user@example.com')));
      expect(capturedMessage, isNot(contains('secret-token')));
    });
  });
}
