import '../entities/appointment_vehicle.dart';
import '../repositories/appointment_booking_repository.dart';

class GetCustomerVehicles {
  const GetCustomerVehicles(this._repository);

  final AppointmentBookingRepository _repository;

  Future<List<AppointmentVehicleRecord>> call({required String workshopId}) {
    return _repository.getCustomerVehicles(workshopId: workshopId);
  }
}
