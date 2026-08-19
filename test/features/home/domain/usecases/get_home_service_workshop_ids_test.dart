import 'package:autolab_customer/features/home/domain/usecases/get_home_service_workshop_ids.dart';
import 'package:autolab_customer/features/products/domain/entities/product.dart';
import 'package:autolab_customer/features/products/domain/repositories/product_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockProductRepository extends Mock implements ProductRepository {}

void main() {
  test('devuelve IDs únicos de talleres con inventario coincidente', () async {
    final repository = _MockProductRepository();
    when(() => repository.getActiveProducts()).thenAnswer(
      (_) async => Right([
        _product(id: 'oil-1', workshopId: 'workshop-1', name: 'Aceite 5W30'),
        _product(
          id: 'oil-2',
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
    final useCase = GetHomeServiceWorkshopIds(productRepository: repository);

    final result = await useCase('cambio_aceite');

    expect(result.getOrElse(() => const []), ['workshop-1']);
    verify(() => repository.getActiveProducts()).called(1);
  });
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
