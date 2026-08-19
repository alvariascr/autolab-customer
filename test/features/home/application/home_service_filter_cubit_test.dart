import 'dart:async';

import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/features/home/application/home_service_filter_cubit.dart';
import 'package:autolab_customer/features/home/application/home_service_filter_state.dart';
import 'package:autolab_customer/features/home/domain/usecases/get_home_service_workshop_ids.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetHomeServiceWorkshopIds extends Mock
    implements GetHomeServiceWorkshopIds {}

class _MockFailure extends Mock implements Failure {}

void main() {
  late _MockGetHomeServiceWorkshopIds getWorkshopIds;

  setUp(() {
    getWorkshopIds = _MockGetHomeServiceWorkshopIds();
  });

  blocTest<HomeServiceFilterCubit, HomeServiceFilterState>(
    'emite carga y talleres coincidentes',
    build: () {
      when(
        () => getWorkshopIds('cambio_aceite'),
      ).thenAnswer((_) async => const Right(['workshop-1']));
      return HomeServiceFilterCubit(getHomeServiceWorkshopIds: getWorkshopIds);
    },
    act: (cubit) => cubit.select(
      serviceKey: 'cambio_aceite',
      serviceLabel: 'Cambio de aceite',
    ),
    expect: () => [
      HomeServiceFilterState(
        status: HomeServiceFilterStatus.loading,
        serviceKey: 'cambio_aceite',
        serviceLabel: 'Cambio de aceite',
      ),
      HomeServiceFilterState(
        status: HomeServiceFilterStatus.success,
        serviceKey: 'cambio_aceite',
        serviceLabel: 'Cambio de aceite',
        matchingWorkshopIds: ['workshop-1'],
      ),
    ],
  );

  blocTest<HomeServiceFilterCubit, HomeServiceFilterState>(
    'expone un estado de error sin confundirlo con cero coincidencias',
    build: () {
      when(
        () => getWorkshopIds('balanceo'),
      ).thenAnswer((_) async => Left(_MockFailure()));
      return HomeServiceFilterCubit(getHomeServiceWorkshopIds: getWorkshopIds);
    },
    act: (cubit) =>
        cubit.select(serviceKey: 'balanceo', serviceLabel: 'Balanceo'),
    expect: () => [
      HomeServiceFilterState(
        status: HomeServiceFilterStatus.loading,
        serviceKey: 'balanceo',
        serviceLabel: 'Balanceo',
      ),
      HomeServiceFilterState(
        status: HomeServiceFilterStatus.failure,
        serviceKey: 'balanceo',
        serviceLabel: 'Balanceo',
      ),
    ],
  );

  blocTest<HomeServiceFilterCubit, HomeServiceFilterState>(
    'clear restablece la selección y los resultados',
    build: () =>
        HomeServiceFilterCubit(getHomeServiceWorkshopIds: getWorkshopIds),
    seed: () => HomeServiceFilterState(
      status: HomeServiceFilterStatus.success,
      serviceKey: 'balanceo',
      serviceLabel: 'Balanceo',
      matchingWorkshopIds: const ['workshop-1'],
    ),
    act: (cubit) => cubit.clear(),
    expect: () => [HomeServiceFilterState()],
  );

  test(
    'ignora una respuesta antigua después de seleccionar otra categoría',
    () async {
      final firstResponse = Completer<Either<Failure, List<String>>>();
      final secondResponse = Completer<Either<Failure, List<String>>>();
      when(
        () => getWorkshopIds('cambio_aceite'),
      ).thenAnswer((_) => firstResponse.future);
      when(
        () => getWorkshopIds('balanceo'),
      ).thenAnswer((_) => secondResponse.future);
      final cubit = HomeServiceFilterCubit(
        getHomeServiceWorkshopIds: getWorkshopIds,
      );

      final firstSelection = cubit.select(
        serviceKey: 'cambio_aceite',
        serviceLabel: 'Cambio de aceite',
      );
      final secondSelection = cubit.select(
        serviceKey: 'balanceo',
        serviceLabel: 'Balanceo',
      );
      secondResponse.complete(const Right(['workshop-2']));
      await secondSelection;
      firstResponse.complete(const Right(['workshop-1']));
      await firstSelection;

      expect(cubit.state.serviceKey, 'balanceo');
      expect(cubit.state.matchingWorkshopIds, ['workshop-2']);
      await cubit.close();
    },
  );
}
