import 'package:autolab_core/autolab_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../repository/auth_repository.dart';
import 'auth_feedback.dart';
import 'password_recovery_state.dart';

class PasswordRecoveryCubit extends Cubit<PasswordRecoveryState> {
  PasswordRecoveryCubit(this._repository)
    : super(const PasswordRecoveryState.initial());

  final AuthRepository _repository;

  Future<void> sendResetEmail({required String email}) async {
    emit(
      state.copyWith(
        status: PasswordRecoveryStatus.submitting,
        clearMessage: true,
        clearCode: true,
        clearUiKey: true,
      ),
    );

    final result = await _repository.sendPasswordResetEmail(email);

    result.fold(
      (Failure failure) => emit(
        state.copyWith(
          status: PasswordRecoveryStatus.error,
          message: authPresentableMessage(failure),
          code: failure.code,
          uiKey: failure.uiKey,
        ),
      ),
      (_) => emit(
        state.copyWith(
          status: PasswordRecoveryStatus.success,
          clearMessage: true,
          clearCode: true,
          clearUiKey: true,
        ),
      ),
    );
  }

  Future<void> updatePassword({required String password}) async {
    emit(
      state.copyWith(
        status: PasswordRecoveryStatus.submitting,
        clearMessage: true,
        clearCode: true,
        clearUiKey: true,
      ),
    );

    final result = await _repository.updatePassword(password);

    result.fold(
      (Failure failure) => emit(
        state.copyWith(
          status: PasswordRecoveryStatus.error,
          message: authPresentableMessage(failure),
          code: failure.code,
          uiKey: failure.uiKey,
        ),
      ),
      (_) => emit(
        state.copyWith(
          status: PasswordRecoveryStatus.success,
          clearMessage: true,
          clearCode: true,
          clearUiKey: true,
        ),
      ),
    );
  }
}
