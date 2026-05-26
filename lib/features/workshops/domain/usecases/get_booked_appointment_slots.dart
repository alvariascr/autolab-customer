import '../repositories/appointment_booking_repository.dart';

class GetBookedAppointmentSlots {
  const GetBookedAppointmentSlots(this._repository);

  final AppointmentBookingRepository _repository;

  Future<List<DateTime>> call({
    required String workshopId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _repository.getBookedAppointmentSlots(
      workshopId: workshopId,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
