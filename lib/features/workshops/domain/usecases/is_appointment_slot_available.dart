import '../repositories/appointment_booking_repository.dart';

class IsAppointmentSlotAvailable {
  const IsAppointmentSlotAvailable(this._repository);

  final AppointmentBookingRepository _repository;

  Future<bool> call({
    required String workshopId,
    required DateTime scheduledDateTime,
    double? serviceDurationHours,
    bool isInspectionService = false,
  }) {
    return _repository.isAppointmentSlotAvailable(
      workshopId: workshopId,
      scheduledDateTime: scheduledDateTime,
      serviceDurationHours: serviceDurationHours,
      isInspectionService: isInspectionService,
    );
  }
}
