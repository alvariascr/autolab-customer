import 'package:autolab_core/autolab_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/appointment.dart';
import '../../domain/repositories/appointment_repository.dart';
import 'my_appointments_state.dart';

class MyAppointmentsCubit extends Cubit<MyAppointmentsState> {
  MyAppointmentsCubit(this._repository)
    : super(const MyAppointmentsState.initial());

  final AppointmentRepository _repository;

  Future<void> load() async {
    if (state.status == MyAppointmentsStatus.loading) {
      return;
    }

    emit(
      state.copyWith(
        status: MyAppointmentsStatus.loading,
        clearMessage: true,
        clearCode: true,
      ),
    );

    final result = await _repository.getCustomerAppointments();
    if (isClosed) {
      return;
    }

    result.fold(_emitFailure, _emitSuccess);
  }

  Future<bool> cancelAppointment({
    required Appointment appointment,
    required String reason,
    String? comments,
  }) async {
    if (state.cancelingAppointmentId != null) {
      return false;
    }

    emit(
      state.copyWith(
        cancelingAppointmentId: appointment.id,
        clearMessage: true,
        clearCode: true,
      ),
    );

    final result = await _repository.cancelAppointment(
      appointmentId: appointment.id,
      reason: reason,
      comments: comments,
    );
    if (isClosed) {
      return false;
    }

    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            message: failure.message,
            code: failure.code,
            clearCancelingAppointmentId: true,
          ),
        );
        return false;
      },
      (updated) {
        final appointments = state.appointments.map((current) {
          return current.id == updated.id ? updated : current;
        }).toList();

        _emitSuccess(appointments);
        emit(state.copyWith(clearCancelingAppointmentId: true));
        return true;
      },
    );
  }

  Future<Appointment?> rescheduleAppointment({
    required Appointment appointment,
    required DateTime scheduledAt,
  }) async {
    if (state.reschedulingAppointmentId != null) {
      return null;
    }

    emit(
      state.copyWith(
        reschedulingAppointmentId: appointment.id,
        clearMessage: true,
        clearCode: true,
      ),
    );

    final result = await _repository.rescheduleAppointment(
      appointmentId: appointment.id,
      scheduledAt: scheduledAt,
    );
    if (isClosed) {
      return null;
    }

    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            message: failure.message,
            code: failure.code,
            clearReschedulingAppointmentId: true,
          ),
        );
        return null;
      },
      (updated) {
        final appointments = state.appointments.map((current) {
          return current.id == updated.id ? updated : current;
        }).toList();

        _emitSuccess(appointments);
        emit(state.copyWith(clearReschedulingAppointmentId: true));
        return updated;
      },
    );
  }

  void _emitFailure(Failure failure) {
    if (isClosed) {
      return;
    }

    emit(
      state.copyWith(
        status: MyAppointmentsStatus.error,
        message: failure.message,
        code: failure.code,
      ),
    );
  }

  void _emitSuccess(List<Appointment> appointments) {
    if (isClosed) {
      return;
    }

    final ordered = [...appointments]
      ..sort((left, right) => left.scheduledAt.compareTo(right.scheduledAt));

    emit(
      state.copyWith(
        status: MyAppointmentsStatus.success,
        appointments: ordered,
        clearMessage: true,
        clearCode: true,
      ),
    );
  }
}
