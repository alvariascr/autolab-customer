import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart';

import '../entities/appointment.dart';

abstract class AppointmentRepository {
  Future<Either<Failure, Appointment>> createAppointment(
    AppointmentDraft draft,
  );

  Future<Either<Failure, List<Appointment>>> getAppointmentsByWorkshop(
    String workshopId,
  );

  Future<Either<Failure, List<Appointment>>> getCustomerAppointments();

  Future<Either<Failure, Appointment>> cancelAppointment({
    required String appointmentId,
    required String reason,
    String? comments,
  });

  Future<Either<Failure, Appointment>> rescheduleAppointment({
    required String appointmentId,
    required DateTime scheduledAt,
  });
}
