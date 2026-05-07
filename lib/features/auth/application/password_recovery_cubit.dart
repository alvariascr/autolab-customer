import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../repository/auth_repository.dart';
import 'auth_feedback.dart';
import 'password_recovery_state.dart';

class PasswordRecoveryCubit extends Cubit<PasswordRecoveryState> {
  PasswordRecoveryCubit(this._repository)
    : super(const PasswordRecoveryState.initial());

  final AuthRepository _repository;

  Future<void> sendResetEmail({required String email}) async {
    _setSubmittingState();
    final result = await _repository.sendPasswordResetEmail(email);
    _handleResult(result);
  }

  Future<void> updatePassword({required String password}) async {
    _setSubmittingState();
    final result = await _repository.updatePassword(password);
    _handleResult(result);
  }

  void _setSubmittingState() {
    emit(
      state.copyWith(
        status: PasswordRecoveryStatus.submitting,
        clearMessage: true,
        clearCode: true,
        clearUiKey: true,
      ),
    );
  }

  void _handleResult(Either<Failure, Unit> result) {
    result.fold(_emitFailure, (_) => _emitSuccess());
  }

  void _emitFailure(Failure failure) {
    emit(
      state.copyWith(
        status: PasswordRecoveryStatus.error,
        message: authPresentableMessage(failure),
        code: failure.code,
        uiKey: failure.uiKey,
      ),
    );
  }

  void _emitSuccess() {
    emit(
      state.copyWith(
        status: PasswordRecoveryStatus.success,
        clearMessage: true,
        clearCode: true,
        clearUiKey: true,
      ),
    );
  }
}
