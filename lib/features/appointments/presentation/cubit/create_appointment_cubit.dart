import 'package:autolab_core/autolab_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/appointment.dart';
import '../../domain/repositories/appointment_repository.dart';
import 'create_appointment_state.dart';

class CreateAppointmentCubit extends Cubit<CreateAppointmentState> {
  CreateAppointmentCubit(this._repository)
    : super(const CreateAppointmentState.initial());

  final AppointmentRepository _repository;

  Future<void> create(AppointmentDraft draft) async {
    if (state.status == CreateAppointmentStatus.submitting) {
      return;
    }

    emit(
      state.copyWith(
        status: CreateAppointmentStatus.submitting,
        clearAppointment: true,
        clearMessage: true,
        clearCode: true,
        clearUiKey: true,
      ),
    );

    final result = await _repository.createAppointment(draft);
    result.fold(_emitFailure, _emitSuccess);
  }

  void _emitFailure(Failure failure) {
    emit(
      state.copyWith(
        status: CreateAppointmentStatus.error,
        message: failure.message,
        code: failure.code,
        uiKey: failure.uiKey,
      ),
    );
  }

  void _emitSuccess(Appointment appointment) {
    emit(
      state.copyWith(
        status: CreateAppointmentStatus.success,
        appointment: appointment,
        clearMessage: true,
        clearCode: true,
        clearUiKey: true,
      ),
    );
  }
}
