import 'package:equatable/equatable.dart';

import '../../domain/entities/appointment.dart';

enum MyAppointmentsStatus { initial, loading, success, error }

class MyAppointmentsState extends Equatable {
  const MyAppointmentsState({
    required this.status,
    this.appointments = const [],
    this.message,
    this.code,
    this.cancelingAppointmentId,
    this.reschedulingAppointmentId,
  });

  const MyAppointmentsState.initial()
    : this(status: MyAppointmentsStatus.initial);

  final MyAppointmentsStatus status;
  final List<Appointment> appointments;
  final String? message;
  final String? code;
  final String? cancelingAppointmentId;
  final String? reschedulingAppointmentId;

  MyAppointmentsState copyWith({
    MyAppointmentsStatus? status,
    List<Appointment>? appointments,
    String? message,
    String? code,
    String? cancelingAppointmentId,
    String? reschedulingAppointmentId,
    bool clearMessage = false,
    bool clearCode = false,
    bool clearCancelingAppointmentId = false,
    bool clearReschedulingAppointmentId = false,
  }) {
    return MyAppointmentsState(
      status: status ?? this.status,
      appointments: appointments ?? this.appointments,
      message: clearMessage ? null : message ?? this.message,
      code: clearCode ? null : code ?? this.code,
      cancelingAppointmentId: clearCancelingAppointmentId
          ? null
          : cancelingAppointmentId ?? this.cancelingAppointmentId,
      reschedulingAppointmentId: clearReschedulingAppointmentId
          ? null
          : reschedulingAppointmentId ?? this.reschedulingAppointmentId,
    );
  }

  @override
  List<Object?> get props => [
    status,
    appointments,
    message,
    code,
    cancelingAppointmentId,
    reschedulingAppointmentId,
  ];
}
