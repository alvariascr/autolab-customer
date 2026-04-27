import 'dart:async';
import 'dart:io';

import 'package:autolab_core/autolab_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExceptionMapper integration', () {
    const mapper = ExceptionMapper();

    test('mapea TimeoutException a TimeoutFailure', () {
      final result = mapper.map(TimeoutException('timeout'));

      expect(result, isA<TimeoutFailure>());
      expect(result.code, ErrorCatalog.requestTimeout.code);
      expect(result.uiKey, ErrorCatalog.requestTimeout.uiKey);
      expect(result.message, ErrorCatalog.requestTimeout.code);
    });

    test('mapea SocketException a NetworkFailure', () {
      final result = mapper.map(const SocketException('sin internet'));

      expect(result, isA<NetworkFailure>());
      expect(result.code, ErrorCatalog.networkUnavailable.code);
      expect(result.uiKey, ErrorCatalog.networkUnavailable.uiKey);
      expect(result.message, ErrorCatalog.networkUnavailable.code);
    });

    test('mapea error desconocido a UnknownFailure', () {
      final result = mapper.map(Exception('random error'));

      expect(result, isA<UnknownFailure>());
    });
  });
}
