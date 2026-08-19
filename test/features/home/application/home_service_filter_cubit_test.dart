import 'dart:async';

import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/features/home/application/home_service_filter_cubit.dart';
import 'package:autolab_customer/features/home/application/home_service_filter_state.dart';
import 'package:autolab_customer/features/products/domain/entities/product.dart';
import 'package:autolab_customer/features/products/domain/repositories/product_repository.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockProductRepository extends Mock implements ProductRepository {}

class _MockFailure extends Mock implements Failure {}

void main() {
  late _MockProductRepository repository;

  setUp(() {
    repository = _MockProductRepository();
  });

  blocTest<HomeServiceFilterCubit, HomeServiceFilterState>(
    'emite carga y talleres coincidentes',
    build: () {
      when(() => repository.getActiveProducts()).thenAnswer(
        (_) async => Right([
          _product(
            id: 'oil-1',
            workshopId: 'workshop-1',
            name: 'Cambio de aceite',
          ),
          _product(
            id: 'tire-1',
            workshopId: 'workshop-2',
            name: 'Llanta deportiva',
          ),
        ]),
      );
      return HomeServiceFilterCubit(productRepository: repository);
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
        () => repository.getActiveProducts(),
      ).thenAnswer((_) async => Left(_MockFailure()));
      return HomeServiceFilterCubit(productRepository: repository);
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

  test(
    'ignora una respuesta antigua después de seleccionar otra categoría',
    () async {
      final firstResponse = Completer<Either<Failure, List<Product>>>();
      final secondResponse = Completer<Either<Failure, List<Product>>>();
      var callCount = 0;
      when(() => repository.getActiveProducts()).thenAnswer((_) {
        callCount++;
        return callCount == 1 ? firstResponse.future : secondResponse.future;
      });
      final cubit = HomeServiceFilterCubit(productRepository: repository);

      final firstSelection = cubit.select(
        serviceKey: 'cambio_aceite',
        serviceLabel: 'Cambio de aceite',
      );
      final secondSelection = cubit.select(
        serviceKey: 'balanceo',
        serviceLabel: 'Balanceo',
      );
      secondResponse.complete(
        Right([
          _product(
            id: 'balance-1',
            workshopId: 'workshop-2',
            name: 'Balanceo computarizado',
          ),
        ]),
      );
      await secondSelection;
      firstResponse.complete(
        Right([
          _product(
            id: 'oil-1',
            workshopId: 'workshop-1',
            name: 'Cambio de aceite',
          ),
        ]),
      );
      await firstSelection;

      expect(cubit.state.serviceKey, 'balanceo');
      expect(cubit.state.matchingWorkshopIds, ['workshop-2']);
      await cubit.close();
    },
  );
}

Product _product({
  required String id,
  required String workshopId,
  required String name,
}) {
  return Product(
    id: id,
    workshopId: workshopId,
    name: name,
    description: '',
    primaryImageUrl: '',
    sellingPrice: 100,
    currentStock: 1,
    minimumStockAlert: 0,
    itemType: 'service',
    status: 'active',
    requiresAppointment: false,
    skuNumber: id,
    barcode: '',
    categoryName: 'Servicios',
    brandName: '',
    providerName: '',
    workshopName: '',
    workshopAvatarUrl: '',
  );
}
