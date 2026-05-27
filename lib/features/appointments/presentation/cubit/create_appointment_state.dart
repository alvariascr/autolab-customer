import 'package:equatable/equatable.dart';

import '../../domain/entities/appointment.dart';

enum CreateAppointmentStatus { initial, submitting, success, error }

class CreateAppointmentState extends Equatable {
  const CreateAppointmentState({
    required this.status,
    this.appointment,
    this.message,
    this.code,
    this.uiKey,
  });

  const CreateAppointmentState.initial()
    : this(status: CreateAppointmentStatus.initial);

  final CreateAppointmentStatus status;
  final Appointment? appointment;
  final String? message;
  final String? code;
  final String? uiKey;

  CreateAppointmentState copyWith({
    CreateAppointmentStatus? status,
    Appointment? appointment,
    String? message,
    String? code,
    String? uiKey,
    bool clearAppointment = false,
    bool clearMessage = false,
    bool clearCode = false,
    bool clearUiKey = false,
  }) {
    return CreateAppointmentState(
      status: status ?? this.status,
      appointment: clearAppointment ? null : appointment ?? this.appointment,
      message: clearMessage ? null : message ?? this.message,
      code: clearCode ? null : code ?? this.code,
      uiKey: clearUiKey ? null : uiKey ?? this.uiKey,
    );
  }

  @override
  List<Object?> get props => [status, appointment, message, code, uiKey];
}
