import '../models/appointment_model.dart';

abstract class AppointmentRemoteDataSource {
  Future<AppointmentModel> createAppointment({
    required Map<String, dynamic> rpcParams,
    required String customerId,
  });

  Future<List<AppointmentModel>> getAppointmentsByWorkshop({
    required String workshopId,
    required String customerId,
  });

  Future<List<AppointmentModel>> getCustomerAppointments({
    required String customerId,
  });
}
