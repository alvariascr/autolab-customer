import 'package:autolab_core/autolab_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/failures/auth_rate_limit_failure.dart';
import '../repository/auth_repository.dart';
import 'register_form_state.dart';

class RegisterFormCubit extends Cubit<RegisterFormState> {
  RegisterFormCubit(this._repository)
    : super(const RegisterFormState.initial());

  final AuthRepository _repository;

  Future<void> submit({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    emit(
      state.copyWith(
        status: RegisterFormStatus.submitting,
        clearMessage: true,
        clearCode: true,
        clearUserId: true,
        clearRemaining: true,
      ),
    );

    final result = await _repository.register(name, email, phone, password);

    result.fold(
      (Failure failure) => emit(
        state.copyWith(
          status: RegisterFormStatus.error,
          message: failure.message,
          code: failure.code,
          remaining: failure is AuthRateLimitFailure ? failure.remaining : null,
          clearUserId: true,
        ),
      ),
      (user) => emit(
        state.copyWith(
          status: RegisterFormStatus.success,
          userId: user.id,
          clearMessage: true,
          clearCode: true,
          clearRemaining: true,
        ),
      ),
    );
  }

  void reset() {
    emit(const RegisterFormState.initial());
  }
}
