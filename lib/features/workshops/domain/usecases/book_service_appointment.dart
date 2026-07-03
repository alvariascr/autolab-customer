import '../entities/appointment_product_selection.dart';
import '../repositories/appointment_booking_repository.dart';

class BookServiceAppointment {
  const BookServiceAppointment(this._repository);

  final AppointmentBookingRepository _repository;

  Future<String> call({
    required String workshopId,
    required String inventoryItemId,
    required DateTime scheduledDateTime,
    List<AppointmentProductSelection> products = const [],
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
    return _repository.bookServiceAppointment(
      workshopId: workshopId,
      inventoryItemId: inventoryItemId,
      scheduledDateTime: scheduledDateTime,
      products: products,
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
