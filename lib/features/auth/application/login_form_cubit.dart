import 'package:autolab_core/autolab_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/failures/auth_rate_limit_failure.dart';
import '../repository/auth_repository.dart';
import 'login_form_state.dart';

class LoginFormCubit extends Cubit<LoginFormState> {
  LoginFormCubit(this._repository) : super(const LoginFormState.initial());

  final AuthRepository _repository;

  Future<void> submit({required String email, required String password}) async {
    emit(
      state.copyWith(
        status: LoginFormStatus.submitting,
        clearMessage: true,
        clearCode: true,
        clearUser: true,
        clearRemaining: true,
      ),
    );

    final result = await _repository.login(email, password);

    result.fold(
      (Failure failure) => emit(
        state.copyWith(
          status: LoginFormStatus.error,
          message: failure.message,
          code: failure.code,
          remaining: failure is AuthRateLimitFailure ? failure.remaining : null,
          clearUser: true,
        ),
      ),
      (user) => emit(
        state.copyWith(
          status: LoginFormStatus.success,
          user: user,
          clearMessage: true,
          clearCode: true,
          clearRemaining: true,
        ),
      ),
    );
  }

  void reset() {
    emit(const LoginFormState.initial());
  }
}
