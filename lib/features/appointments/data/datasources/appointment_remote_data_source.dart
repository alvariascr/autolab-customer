import '../models/appointment_model.dart';

abstract class AppointmentRemoteDataSource {
  Future<List<AppointmentModel>> getAppointmentsByWorkshop({
    required String workshopId,
    required String customerId,
  });

  Future<List<AppointmentModel>> getCustomerAppointments({
    required String customerId,
  });

  Future<AppointmentModel> cancelAppointment({
    required String appointmentId,
    required String customerId,
    required String reason,
    String? comments,
  });

  Future<AppointmentModel> rescheduleAppointment({
    required String appointmentId,
    required String customerId,
    required DateTime scheduledAt,
  });
}
