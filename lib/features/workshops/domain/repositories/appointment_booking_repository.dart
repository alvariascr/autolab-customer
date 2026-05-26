import '../entities/appointment_vehicle.dart';

abstract class AppointmentBookingRepository {
  Future<List<AppointmentVehicleRecord>> getCustomerVehicles({
    required String workshopId,
  });

  Future<AppointmentVehicleRecord?> getCustomerVehicleByPlate({
    required String workshopId,
    required String licensePlate,
  });

  Future<bool> isAppointmentSlotAvailable({
    required String workshopId,
    required DateTime scheduledDateTime,
  });

  Future<List<DateTime>> getBookedAppointmentSlots({
    required String workshopId,
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<String> bookServiceAppointment({
    required String workshopId,
    required String inventoryItemId,
    required DateTime scheduledDateTime,
    String? note,
    String? vehicleId,
    String? licensePlate,
    String? vehicleType,
    String? vehicleBrand,
    String? vehicleModel,
    int? vehicleYear,
    String? vehicleColor,
    String? fuelType,
    String? transmissionType,
  });
}
