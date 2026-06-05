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
