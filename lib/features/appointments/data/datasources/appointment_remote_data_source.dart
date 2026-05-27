import '../../domain/entities/appointment.dart';
import '../models/appointment_model.dart';

abstract class AppointmentRemoteDataSource {
  Future<AppointmentModel> createAppointment(AppointmentDraft draft);

  Future<List<AppointmentModel>> getAppointmentsByWorkshop(String workshopId);
}
