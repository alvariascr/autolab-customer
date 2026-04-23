import 'package:autolab_core/autolab_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/entities/app_user.dart';
import '../domain/errors/auth_error_catalog.dart';
import '../repository/auth_repository.dart';
import 'auth_session_state.dart';

class AuthSessionCubit extends Cubit<AuthSessionState> {
  AuthSessionCubit(this._repository) : super(const AuthSessionState.initial());

  final AuthRepository _repository;

  Future<void> restoreSession() async {
    emit(
      state.copyWith(
        status: AuthSessionStatus.loading,
        clearMessage: true,
        clearCode: true,
        clearUiKey: true,
      ),
    );

    try {
      final user = await _repository.getCurrentUser();
      if (user == null) {
        emit(
          state.copyWith(
            status: AuthSessionStatus.unauthenticated,
            clearUser: true,
            clearMessage: true,
            clearCode: true,
            clearUiKey: true,
          ),
        );
        return;
      }

      setAuthenticated(user);
    } catch (error, stackTrace) {
      final failure = UnknownFailure.fromErrorItem(
        AuthErrorCatalog.sessionRestoreFailed,
        cause: error,
        stackTrace: stackTrace,
      );

      emit(
        state.copyWith(
          status: AuthSessionStatus.unauthenticated,
          clearUser: true,
          message: failure.message,
          code: failure.code,
          uiKey: failure.uiKey,
        ),
      );
    }
  }

  void setAuthenticated(AppUser user) {
    emit(
      AuthSessionState(
        status: AuthSessionStatus.authenticated,
        userId: user.id,
        role: user.role,
        code: null,
        uiKey: null,
      ),
    );
  }

  Future<void> logout() async {
    final previousState = state;

    emit(
      state.copyWith(
        status: AuthSessionStatus.loading,
        clearMessage: true,
        clearCode: true,
        clearUiKey: true,
      ),
    );

    final result = await _repository.logout();

    result.fold(
      (Failure failure) {
        if (previousState.isAuthenticated) {
          emit(
            previousState.copyWith(
              message: failure.message,
              code: failure.code,
              uiKey: failure.uiKey,
            ),
          );
          return;
        }

        emit(
          state.copyWith(
            status: AuthSessionStatus.unauthenticated,
            clearUser: true,
            message: failure.message,
            code: failure.code,
            uiKey: failure.uiKey,
          ),
        );
      },
      (_) {
        emit(const AuthSessionState(status: AuthSessionStatus.unauthenticated));
      },
    );
  }
}
