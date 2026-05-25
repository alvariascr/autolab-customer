import 'package:autolab_customer/features/products/domain/entities/product.dart';
import 'package:autolab_customer/features/products/domain/repositories/product_repository.dart';
import 'package:autolab_customer/features/products/domain/usecases/get_additional_products_by_workshop.dart';
import 'package:autolab_customer/features/products/domain/usecases/get_schedulable_services_by_workshop.dart';
import 'package:autolab_customer/features/workshops/application/appointment_cubit.dart';
import 'package:autolab_customer/features/workshops/data/datasources/appointment_booking_remote_data_source.dart';
import 'package:autolab_customer/features/workshops/domain/repositories/workshop_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWorkshopRepository extends Mock implements WorkshopRepository {}

class MockProductRepository extends Mock implements ProductRepository {}

class MockAppointmentBookingRemoteDataSource extends Mock
    implements AppointmentBookingRemoteDataSource {}

void main() {
  late AppointmentCubit cubit;
  late MockAppointmentBookingRemoteDataSource bookingRemoteDataSource;

  setUp(() {
    final productRepository = MockProductRepository();
    bookingRemoteDataSource = MockAppointmentBookingRemoteDataSource();
    cubit = AppointmentCubit(
      workshopRepository: MockWorkshopRepository(),
      getSchedulableServices: GetSchedulableServicesByWorkshop(
        productRepository,
      ),
      getAdditionalProducts: GetAdditionalProductsByWorkshop(productRepository),
      bookingRemoteDataSource: bookingRemoteDataSource,
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

  test(
    'submitBooking calls backend transaction with selected service slot',
    () async {
      final service = _product(id: 'service-1', itemType: 'service');
      final selectedDate = DateTime(2026, 5, 28);

      when(
        () => bookingRemoteDataSource.bookServiceAppointment(
          workshopId: 'workshop-1',
          inventoryItemId: 'service-1',
          scheduledDateTime: any(named: 'scheduledDateTime'),
          note: any(named: 'note'),
          vehicleId: any(named: 'vehicleId'),
          licensePlate: any(named: 'licensePlate'),
          vehicleType: any(named: 'vehicleType'),
          vehicleBrand: any(named: 'vehicleBrand'),
          vehicleModel: any(named: 'vehicleModel'),
          vehicleYear: any(named: 'vehicleYear'),
          vehicleColor: any(named: 'vehicleColor'),
          fuelType: any(named: 'fuelType'),
          transmissionType: any(named: 'transmissionType'),
        ),
      ).thenAnswer((_) async => 'appointment-1');

      cubit
        ..updateVehicleLicensePlate('abc123')
        ..updateVehicleType('Sedan')
        ..updateVehicleBrand('Toyota')
        ..updateVehicleModel('Yaris')
        ..updateVehicleYear('2019')
        ..updateVehicleColor('Negro')
        ..updateVehicleFuelType('gasoline')
        ..updateVehicleTransmissionType('manual')
        ..selectService(service)
        ..selectDate(selectedDate)
        ..selectTime('06:15');

      final appointmentId = await cubit.submitBooking();

      expect(appointmentId, 'appointment-1');
      expect(cubit.state.createdAppointmentId, 'appointment-1');

      verify(
        () => bookingRemoteDataSource.bookServiceAppointment(
          workshopId: 'workshop-1',
          inventoryItemId: 'service-1',
          scheduledDateTime: DateTime(2026, 5, 28, 6, 15),
          note: any(named: 'note'),
          vehicleId: any(named: 'vehicleId'),
          licensePlate: 'ABC123',
          vehicleType: 'Sedan',
          vehicleBrand: 'Toyota',
          vehicleModel: 'Yaris',
          vehicleYear: 2019,
          vehicleColor: 'Negro',
          fuelType: 'gasoline',
          transmissionType: 'manual',
        ),
      ).called(1);
    },
  );
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
