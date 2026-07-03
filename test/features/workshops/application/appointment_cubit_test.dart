import 'package:autolab_customer/features/products/domain/entities/product.dart';
import 'package:autolab_customer/features/products/domain/repositories/product_repository.dart';
import 'package:autolab_customer/features/products/domain/usecases/get_additional_products_by_workshop.dart';
import 'package:autolab_customer/features/products/domain/usecases/get_schedulable_services_by_workshop.dart';
import 'package:autolab_customer/features/workshops/application/appointment_cubit.dart';
import 'package:autolab_customer/features/workshops/domain/entities/appointment_product_selection.dart';
import 'package:autolab_customer/features/workshops/domain/entities/appointment_vehicle.dart';
import 'package:autolab_customer/features/workshops/domain/repositories/workshop_repository.dart';
import 'package:autolab_customer/features/workshops/domain/usecases/book_service_appointment.dart';
import 'package:autolab_customer/features/workshops/domain/usecases/get_booked_appointment_slots.dart';
import 'package:autolab_customer/features/workshops/domain/usecases/get_customer_vehicle_by_plate.dart';
import 'package:autolab_customer/features/workshops/domain/usecases/get_customer_vehicles.dart';
import 'package:autolab_customer/features/workshops/domain/usecases/is_appointment_slot_available.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWorkshopRepository extends Mock implements WorkshopRepository {}

class MockProductRepository extends Mock implements ProductRepository {}

class MockGetCustomerVehicles extends Mock implements GetCustomerVehicles {}

class MockGetCustomerVehicleByPlate extends Mock
    implements GetCustomerVehicleByPlate {}

class MockIsAppointmentSlotAvailable extends Mock
    implements IsAppointmentSlotAvailable {}

class MockGetBookedAppointmentSlots extends Mock
    implements GetBookedAppointmentSlots {}

class MockBookServiceAppointment extends Mock
    implements BookServiceAppointment {}

void main() {
  late AppointmentCubit cubit;
  late MockBookServiceAppointment bookServiceAppointment;

  setUpAll(() {
    registerFallbackValue(<AppointmentProductSelection>[]);
  });

  setUp(() {
    final productRepository = MockProductRepository();
    bookServiceAppointment = MockBookServiceAppointment();
    cubit = _createCubit(
      productRepository: productRepository,
      workshopRepository: MockWorkshopRepository(),
      bookServiceAppointment: bookServiceAppointment,
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

  test('load preselects the requested schedulable service', () async {
    final service = _product(id: 'service-1', itemType: 'service');
    final additionalProduct = _product(id: 'product-1', itemType: 'product');
    final productRepository = MockProductRepository();
    final workshopRepository = MockWorkshopRepository();
    final preselectedCubit = _createCubit(
      workshopRepository: workshopRepository,
      productRepository: productRepository,
      bookServiceAppointment: MockBookServiceAppointment(),
    );
    addTearDown(preselectedCubit.close);

    when(
      () => productRepository.getActiveProductsByWorkshop('workshop-1'),
    ).thenAnswer((_) async => Right([service, additionalProduct]));
    when(
      () => workshopRepository.getWorkshopById('workshop-1'),
    ).thenAnswer((_) async => const Right(null));

    await preselectedCubit.load('workshop-1', initialService: service);

    expect(preselectedCubit.state.selectedService, service);
    expect(preselectedCubit.state.services, [service]);
    expect(preselectedCubit.state.products, [additionalProduct]);
  });

  test(
    'submitBooking calls backend transaction with selected service slot',
    () async {
      final service = _product(id: 'service-1', itemType: 'service');
      final selectedDate = DateTime(2030, 6, 28);

      when(
        () => bookServiceAppointment(
          workshopId: 'workshop-1',
          inventoryItemId: 'service-1',
          scheduledDateTime: any(named: 'scheduledDateTime'),
          products: any<List<AppointmentProductSelection>>(named: 'products'),
          note: any(named: 'note'),
          vehicleId: any(named: 'vehicleId'),
          garageVehicleId: any(named: 'garageVehicleId'),
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
        () => bookServiceAppointment(
          workshopId: 'workshop-1',
          inventoryItemId: 'service-1',
          scheduledDateTime: DateTime(2030, 6, 28, 6, 15),
          products: const [],
          note: any(named: 'note'),
          vehicleId: null,
          garageVehicleId: null,
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

  test('submitBooking sends selected garage vehicle id', () async {
    final service = _product(id: 'service-1', itemType: 'service');

    when(
      () => bookServiceAppointment(
        workshopId: 'workshop-1',
        inventoryItemId: 'service-1',
        scheduledDateTime: any(named: 'scheduledDateTime'),
        products: any<List<AppointmentProductSelection>>(named: 'products'),
        note: any(named: 'note'),
        vehicleId: any(named: 'vehicleId'),
        garageVehicleId: any(named: 'garageVehicleId'),
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
      ..selectExistingVehicle(
        const AppointmentVehicleRecord(
          id: 'garage-vehicle-1',
          licensePlate: 'ABC123',
          vehicleType: 'Sedan',
          brand: 'Toyota',
          model: 'Yaris',
          year: 2019,
          color: 'Negro',
          fuelType: 'gasoline',
          transmissionType: 'manual',
        ),
      )
      ..selectService(service)
      ..selectDate(DateTime(2030, 6, 28))
      ..selectTime('06:15');

    final appointmentId = await cubit.submitBooking();

    expect(appointmentId, 'appointment-1');

    verify(
      () => bookServiceAppointment(
        workshopId: 'workshop-1',
        inventoryItemId: 'service-1',
        scheduledDateTime: DateTime(2030, 6, 28, 6, 15),
        products: const [],
        note: any(named: 'note'),
        vehicleId: null,
        garageVehicleId: 'garage-vehicle-1',
        licensePlate: null,
        vehicleType: null,
        vehicleBrand: null,
        vehicleModel: null,
        vehicleYear: null,
        vehicleColor: null,
        fuelType: null,
        transmissionType: null,
      ),
    ).called(1);
  });

  test(
    'submitBooking sends selected additional products after quantity increment',
    () async {
      final service = _product(id: 'service-1', itemType: 'service');
      final product = _product(id: 'product-1', itemType: 'product');

      when(
        () => bookServiceAppointment(
          workshopId: 'workshop-1',
          inventoryItemId: 'service-1',
          scheduledDateTime: any(named: 'scheduledDateTime'),
          products: any<List<AppointmentProductSelection>>(named: 'products'),
          note: any(named: 'note'),
          vehicleId: any(named: 'vehicleId'),
          garageVehicleId: any(named: 'garageVehicleId'),
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
        ..selectService(service)
        ..setIncludeProducts(true)
        ..toggleProduct(product)
        ..changeProductQuantity(product, 1)
        ..selectDate(DateTime(2026, 7, 28))
        ..selectTime('06:15');

      final appointmentId = await cubit.submitBooking();

      expect(appointmentId, 'appointment-1');

      final captured =
          verify(
                () => bookServiceAppointment(
                  workshopId: 'workshop-1',
                  inventoryItemId: 'service-1',
                  scheduledDateTime: DateTime(2026, 7, 28, 6, 15),
                  products: captureAny<List<AppointmentProductSelection>>(
                    named: 'products',
                  ),
                  note: any(named: 'note'),
                  vehicleId: null,
                  garageVehicleId: null,
                  licensePlate: 'ABC123',
                  vehicleType: null,
                  vehicleBrand: null,
                  vehicleModel: null,
                  vehicleYear: null,
                  vehicleColor: null,
                  fuelType: null,
                  transmissionType: null,
                ),
              ).captured.single
              as List;

      expect(captured.single.inventoryItemId, 'product-1');
      expect(captured.single.quantity, 2);
    },
  );
}

AppointmentCubit _createCubit({
  required WorkshopRepository workshopRepository,
  required ProductRepository productRepository,
  required BookServiceAppointment bookServiceAppointment,
}) {
  return AppointmentCubit(
    workshopRepository: workshopRepository,
    getSchedulableServices: GetSchedulableServicesByWorkshop(productRepository),
    getAdditionalProducts: GetAdditionalProductsByWorkshop(productRepository),
    getCustomerVehicles: MockGetCustomerVehicles(),
    getCustomerVehicleByPlate: MockGetCustomerVehicleByPlate(),
    isAppointmentSlotAvailable: MockIsAppointmentSlotAvailable(),
    getBookedAppointmentSlots: MockGetBookedAppointmentSlots(),
    bookServiceAppointment: bookServiceAppointment,
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
