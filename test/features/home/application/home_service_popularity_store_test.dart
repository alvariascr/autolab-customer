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
}
