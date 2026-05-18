import 'package:autolab_customer/features/products/domain/entities/product.dart';
import 'package:autolab_customer/features/products/domain/repositories/product_repository.dart';
import 'package:autolab_customer/features/products/domain/usecases/get_additional_products_by_workshop.dart';
import 'package:autolab_customer/features/products/domain/usecases/get_schedulable_services_by_workshop.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  const workshopId = 'workshop-1';
  late MockProductRepository repository;

  setUp(() {
    repository = MockProductRepository();
  });

  test(
    'GetSchedulableServicesByWorkshop returns only valid services',
    () async {
      final products = [
        _product(
          id: 'service-1',
          itemType: 'service',
          isSchedulable: true,
          requiresAppointment: true,
        ),
        _product(
          id: 'service-2',
          itemType: 'service',
          isSchedulable: true,
          requiresAppointment: false,
        ),
        _product(
          id: 'product-1',
          itemType: 'product',
          isSchedulable: true,
          requiresAppointment: true,
        ),
      ];
      when(
        () => repository.getActiveProductsByWorkshop(workshopId),
      ).thenAnswer((_) async => Right(products));

      final result = await GetSchedulableServicesByWorkshop(
        repository,
      ).call(workshopId);

      expect(result.getOrElse(() => const []), [products.first]);
    },
  );

  test('GetAdditionalProductsByWorkshop excludes service items', () async {
    final products = [
      _product(id: 'service-1', itemType: 'service'),
      _product(id: 'product-1', itemType: 'product'),
      _product(id: 'part-1', itemType: 'part'),
    ];
    when(
      () => repository.getActiveProductsByWorkshop(workshopId),
    ).thenAnswer((_) async => Right(products));

    final result = await GetAdditionalProductsByWorkshop(
      repository,
    ).call(workshopId);

    expect(result.getOrElse(() => const []), [products[1], products[2]]);
  });
}

Product _product({
  required String id,
  required String itemType,
  bool isSchedulable = false,
  bool requiresAppointment = false,
}) {
  return Product(
    id: id,
    workshopId: 'workshop-1',
    name: id,
    description: '',
    primaryImageUrl: '',
    sellingPrice: null,
    currentStock: null,
    minimumStockAlert: null,
    itemType: itemType,
    status: 'active',
    requiresAppointment: requiresAppointment,
    isSchedulable: isSchedulable,
    skuNumber: '',
    barcode: '',
    categoryName: '',
    brandName: '',
    providerName: '',
    workshopName: 'Autolab',
    workshopAvatarUrl: '',
  );
}
