import 'package:autolab_core/autolab_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logging/feature_logger.dart';
import '../domain/entities/app_user.dart';
import '../domain/errors/auth_error_catalog.dart';
import '../repository/auth_repository.dart';
import 'auth_session_state.dart';

class AuthSessionCubit extends Cubit<AuthSessionState> {
  AuthSessionCubit(this._repository, this._featureLogger)
    : super(const AuthSessionState.initial());

  final AuthRepository _repository;
  final FeatureLogger _featureLogger;

  Future<void> restoreSession() async {
    _featureLogger.info(
      feature: 'auth',
      action: 'restore_session_started',
    );

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
        _featureLogger.info(
          feature: 'auth',
          action: 'restore_session_empty',
        );
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

      _featureLogger.info(
        feature: 'auth',
        action: 'restore_session_succeeded',
        context: {'role': user.role, 'userId': user.id},
      );
      setAuthenticated(user);
    } catch (error, stackTrace) {
      final failure = UnknownFailure.fromErrorItem(
        AuthErrorCatalog.sessionRestoreFailed,
        cause: error,
        stackTrace: stackTrace,
      );

      _featureLogger.error(
        feature: 'auth',
        action: 'restore_session_failed',
        code: failure.code,
        context: {'uiKey': failure.uiKey},
        error: error,
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

    _featureLogger.info(
      feature: 'auth',
      action: 'logout_started',
      context: {'wasAuthenticated': previousState.isAuthenticated},
    );

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
        _featureLogger.warn(
          feature: 'auth',
          action: 'logout_failed',
          code: failure.code,
          context: {'uiKey': failure.uiKey},
          error: failure.cause,
          stackTrace: failure.stackTrace,
        );

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
        _featureLogger.info(
          feature: 'auth',
          action: 'logout_succeeded',
        );
        emit(const AuthSessionState(status: AuthSessionStatus.unauthenticated));
      },
    );
  }

  void clearFeedback() {
    if (state.message == null && state.code == null && state.uiKey == null) {
      return;
    }

    emit(
      state.copyWith(
        clearMessage: true,
        clearCode: true,
        clearUiKey: true,
      ),
    );
  }
}
