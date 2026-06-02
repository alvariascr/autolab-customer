import 'package:equatable/equatable.dart';

import '../../domain/entities/appointment.dart';

enum MyAppointmentsStatus { initial, loading, success, error }

class MyAppointmentsState extends Equatable {
  const MyAppointmentsState({
    required this.status,
    this.appointments = const [],
    this.message,
    this.code,
  });

  const MyAppointmentsState.initial()
    : this(status: MyAppointmentsStatus.initial);

  final MyAppointmentsStatus status;
  final List<Appointment> appointments;
  final String? message;
  final String? code;

  MyAppointmentsState copyWith({
    MyAppointmentsStatus? status,
    List<Appointment>? appointments,
    String? message,
    String? code,
    bool clearMessage = false,
    bool clearCode = false,
  }) {
    return MyAppointmentsState(
      status: status ?? this.status,
      appointments: appointments ?? this.appointments,
      message: clearMessage ? null : message ?? this.message,
      code: clearCode ? null : code ?? this.code,
    );
  }

  @override
  List<Object?> get props => [status, appointments, message, code];
}
