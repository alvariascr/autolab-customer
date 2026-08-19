import 'package:autolab_customer/features/home/domain/home_service_inventory_matcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const matcher = HomeServiceInventoryMatcher();

  test('encuentra coincidencias sin importar tildes o mayusculas', () {
    expect(
      matcher.matches(
        serviceKey: 'alineamiento',
        name: 'Alineación computarizada',
        categoryName: 'Servicios',
      ),
      isTrue,
    );
  });

  test('no mezcla una categoria con inventario no relacionado', () {
    expect(
      matcher.matches(
        serviceKey: 'baterias',
        name: 'Cambio de aceite',
        categoryName: 'Lubricantes',
      ),
      isFalse,
    );
  });

  test('una llanta disponible cuenta para cambio y reparacion de llanta', () {
    for (final serviceKey in const ['cambio_llanta', 'reparacion_llanta']) {
      expect(
        matcher.matches(
          serviceKey: serviceKey,
          name: 'Llanta 205/55 R16',
          categoryName: 'Llantas',
        ),
        isTrue,
        reason: 'La coincidencia amplia es intencional para $serviceKey',
      );
    }
  });
}
