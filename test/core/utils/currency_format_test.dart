import 'package:autolab_customer/core/utils/currency_format.dart';
import 'package:flutter_test/flutter_test.dart';

// NumberFormat.currency separates the amount from the symbol with a
// non-breaking space (U+00A0), not a regular space -- built from its code
// point so it isn't silently lost/normalized in the source file.
final _nbsp = String.fromCharCode(0xA0);

void main() {
  group('formatColones', () {
    test('agrega separador de miles y sin decimales', () {
      expect(formatColones(15000), '15.000$_nbsp₡');
    });

    test('no agrega separador para montos menores a mil', () {
      expect(formatColones(500), '500$_nbsp₡');
    });

    test('redondea a un entero', () {
      expect(formatColones(1500.75), '1.501$_nbsp₡');
    });

    test('formatea cero correctamente', () {
      expect(formatColones(0), '0$_nbsp₡');
    });
  });
}
