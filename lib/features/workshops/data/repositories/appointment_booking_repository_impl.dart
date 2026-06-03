import '../../domain/entities/appointment_vehicle.dart';
import '../../domain/entities/booked_appointment_slot.dart';
import '../../domain/repositories/appointment_booking_repository.dart';
import '../datasources/appointment_booking_remote_data_source.dart';

class AppointmentBookingRepositoryImpl implements AppointmentBookingRepository {
  const AppointmentBookingRepositoryImpl(this._remoteDataSource);

  final AppointmentBookingRemoteDataSource _remoteDataSource;

  @override
  Future<List<AppointmentVehicleRecord>> getCustomerVehicles({
    required String workshopId,
  }) {
    return _remoteDataSource.getCustomerVehicles(workshopId: workshopId);
  }

  @override
  Future<AppointmentVehicleRecord?> getCustomerVehicleByPlate({
    required String workshopId,
    required String licensePlate,
  }) {
    return _remoteDataSource.getCustomerVehicleByPlate(
      workshopId: workshopId,
      licensePlate: licensePlate,
    );
  }

  @override
  Future<bool> isAppointmentSlotAvailable({
    required String workshopId,
    required DateTime scheduledDateTime,
  }) {
    return _remoteDataSource.isAppointmentSlotAvailable(
      workshopId: workshopId,
      scheduledDateTime: scheduledDateTime,
    );
  }

  @override
  Future<List<BookedAppointmentSlot>> getBookedAppointmentSlots({
    required String workshopId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _remoteDataSource.getBookedAppointmentSlots(
      workshopId: workshopId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<String> bookServiceAppointment({
    required String workshopId,
    required String inventoryItemId,
    required DateTime scheduledDateTime,
    String? note,
    String? vehicleId,
    String? garageVehicleId,
    String? licensePlate,
    String? vehicleType,
    String? vehicleBrand,
    String? vehicleModel,
    int? vehicleYear,
    String? vehicleColor,
    String? fuelType,
    String? transmissionType,
  }) {
    return _remoteDataSource.bookServiceAppointment(
      workshopId: workshopId,
      inventoryItemId: inventoryItemId,
      scheduledDateTime: scheduledDateTime,
      note: note,
      vehicleId: vehicleId,
      garageVehicleId: garageVehicleId,
      licensePlate: licensePlate,
      vehicleType: vehicleType,
      vehicleBrand: vehicleBrand,
      vehicleModel: vehicleModel,
      vehicleYear: vehicleYear,
      vehicleColor: vehicleColor,
      fuelType: fuelType,
      transmissionType: transmissionType,
    );
  }
}
