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
      expect(result.message, 'La operación tardó demasiado. Intenta de nuevo.');
    });

    test('mapea SocketException a NetworkFailure', () {
      final result = mapper.map(const SocketException('sin internet'));

      expect(result, isA<NetworkFailure>());
      expect(result.message, 'Error de conexión. Verifica tu internet.');
    });

    test('mapea error desconocido a UnknownFailure', () {
      final result = mapper.map(Exception('random error'));

      expect(result, isA<UnknownFailure>());
    });
  });
}
