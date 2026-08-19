import 'package:autolab_customer/features/home/application/home_service_popularity_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ordena por conteo descendente', () {
    final result = sortByServicePopularity<String>(
      items: const ['inspeccion', 'aceite', 'llantas'],
      serviceKeyOf: (item) => item,
      clickCounts: const {'aceite': 4, 'llantas': 9},
    );

    expect(result, ['llantas', 'aceite', 'inspeccion']);
  });

  test('conserva el orden original cuando los conteos empatan', () {
    final result = sortByServicePopularity<String>(
      items: const ['inspeccion', 'aceite', 'llantas'],
      serviceKeyOf: (item) => item,
      clickCounts: const {'inspeccion': 2, 'aceite': 2, 'llantas': 2},
    );

    expect(result, ['inspeccion', 'aceite', 'llantas']);
  });

  test('admite mapas de conteo incompletos', () {
    final result = sortByServicePopularity<String>(
      items: const ['inspeccion', 'aceite', 'llantas'],
      serviceKeyOf: (item) => item,
      clickCounts: const {'llantas': 2},
    );

    expect(result, ['llantas', 'inspeccion', 'aceite']);
  });

  test('ignora claves de conteo compuestas solo por espacios', () {
    final result = sortByServicePopularity<String>(
      items: const ['inspeccion', 'aceite'],
      serviceKeyOf: (item) => item,
      clickCounts: const {'   ': 99, 'aceite': 1},
    );

    expect(result, ['aceite', 'inspeccion']);
  });

  test('devuelve una lista vacía cuando no hay categorías', () {
    final result = sortByServicePopularity<String>(
      items: const [],
      serviceKeyOf: (item) => item,
      clickCounts: const {},
    );

    expect(result, isEmpty);
  });
}
