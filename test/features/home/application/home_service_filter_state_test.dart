import 'package:autolab_customer/features/home/application/home_service_filter_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('copyWith conserva la selección y permite limpiar resultados', () {
    final state = HomeServiceFilterState(
      status: HomeServiceFilterStatus.success,
      serviceKey: 'balanceo',
      serviceLabel: 'Balanceo',
      matchingWorkshopIds: const ['workshop-1'],
    );

    final loading = state.copyWith(
      status: HomeServiceFilterStatus.loading,
      clearMatchingWorkshopIds: true,
    );

    expect(loading.serviceKey, 'balanceo');
    expect(loading.serviceLabel, 'Balanceo');
    expect(loading.matchingWorkshopIds, isEmpty);
  });

  test('copyWith permite limpiar la selección explícitamente', () {
    final state = HomeServiceFilterState(
      serviceKey: 'balanceo',
      serviceLabel: 'Balanceo',
    );

    final cleared = state.copyWith(clearSelection: true);

    expect(cleared.serviceKey, isNull);
    expect(cleared.serviceLabel, isNull);
  });
}
