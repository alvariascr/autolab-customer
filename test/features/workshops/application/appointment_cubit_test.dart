import 'package:autolab_customer/features/products/domain/entities/product.dart';
import 'package:autolab_customer/features/products/domain/repositories/product_repository.dart';
import 'package:autolab_customer/features/products/domain/usecases/get_additional_products_by_workshop.dart';
import 'package:autolab_customer/features/products/domain/usecases/get_schedulable_services_by_workshop.dart';
import 'package:autolab_customer/features/workshops/application/appointment_cubit.dart';
import 'package:autolab_customer/features/workshops/domain/repositories/workshop_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWorkshopRepository extends Mock implements WorkshopRepository {}

class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late AppointmentCubit cubit;

  setUp(() {
    final productRepository = MockProductRepository();
    cubit = AppointmentCubit(
      workshopRepository: MockWorkshopRepository(),
      getSchedulableServices: GetSchedulableServicesByWorkshop(
        productRepository,
      ),
      getAdditionalProducts: GetAdditionalProductsByWorkshop(productRepository),
    );
  });

  tearDown(() => cubit.close());

  test('goNext and goBack update the current step', () {
    cubit.goNext();
    expect(cubit.state.currentStep, 1);

    cubit.goBack();
    expect(cubit.state.currentStep, 0);
  });

  test('selectService clears dependent product and schedule state', () {
    final service = _product(id: 'service-1', itemType: 'service');
    final product = _product(id: 'product-1', itemType: 'product');

    cubit.setIncludeProducts(true);
    cubit.toggleProduct(product);
    cubit.selectDate(DateTime.utc(2026, 5, 28));
    cubit.selectTime('06:15');
    cubit.selectService(service);

    expect(cubit.state.selectedService, service);
    expect(cubit.state.includeProducts, isFalse);
    expect(cubit.state.selectedProducts, isEmpty);
    expect(cubit.state.selectedDate, isNull);
    expect(cubit.state.selectedTime, isNull);
  });
}

Product _product({required String id, required String itemType}) {
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
    requiresAppointment: true,
    isSchedulable: true,
    skuNumber: '',
    barcode: '',
    categoryName: '',
    brandName: '',
    providerName: '',
    workshopName: 'Autolab',
    workshopAvatarUrl: '',
  );
}
