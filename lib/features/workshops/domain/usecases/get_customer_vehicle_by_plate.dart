import '../entities/appointment_vehicle.dart';
import '../repositories/appointment_booking_repository.dart';

class GetCustomerVehicleByPlate {
  const GetCustomerVehicleByPlate(this._repository);

  final AppointmentBookingRepository _repository;

  Future<AppointmentVehicleRecord?> call({
    required String workshopId,
    required String licensePlate,
  }) {
    return _repository.getCustomerVehicleByPlate(
      workshopId: workshopId,
      licensePlate: licensePlate,
    );
  }
}
