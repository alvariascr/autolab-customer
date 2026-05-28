import 'package:autolab_customer/features/appointments/domain/entities/appointment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppointmentProductLine', () {
    test('permite una linea valida', () {
      const line = AppointmentProductLine(
        productId: 'product-1',
        quantity: 1,
        unitPrice: 5000,
      );

      expect(line.productId, 'product-1');
      expect(line.quantity, 1);
      expect(line.unitPrice, 5000);
    });

    test('falla cuando productId esta vacio', () {
      expect(
        () => AppointmentProductLine(productId: '', quantity: 1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('falla cuando quantity no es positiva', () {
      expect(
        () => AppointmentProductLine(productId: 'product-1', quantity: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('falla cuando unitPrice es negativo', () {
      expect(
        () => AppointmentProductLine(
          productId: 'product-1',
          quantity: 1,
          unitPrice: -1,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
