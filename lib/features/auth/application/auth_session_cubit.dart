import 'package:autolab_core/autolab_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logging/feature_logger.dart';
import '../domain/entities/app_user.dart';
import '../repository/auth_repository.dart';
import 'auth_feedback.dart';
import 'auth_session_state.dart';

class AuthSessionCubit extends Cubit<AuthSessionState> {
  AuthSessionCubit(this._repository, this._featureLogger)
    : super(const AuthSessionState.initial());

  final AuthRepository _repository;
  final FeatureLogger _featureLogger;

  Future<void> restoreSession() async {
    _featureLogger.info(feature: 'auth', action: 'restore_session_started');

    emit(
      state.copyWith(
        status: AuthSessionStatus.loading,
        clearMessage: true,
        clearCode: true,
        clearUiKey: true,
      ),
    );

    final result = await _repository.getCurrentUser();

    result.fold(
      (failure) {
        _featureLogger.error(
          feature: 'auth',
          action: 'restore_session_failed',
          code: failure.code,
          context: {'uiKey': failure.uiKey},
          error: failure.cause,
          stackTrace: failure.stackTrace,
        );

        emit(
          state.copyWith(
            status: AuthSessionStatus.unauthenticated,
            clearUser: true,
            message: authPresentableMessage(failure),
            code: failure.code,
            uiKey: failure.uiKey,
          ),
        );
      },
      (user) {
        if (user == null) {
          _featureLogger.info(feature: 'auth', action: 'restore_session_empty');
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
      },
    );
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
              message: authPresentableMessage(failure),
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
            message: authPresentableMessage(failure),
            code: failure.code,
            uiKey: failure.uiKey,
          ),
        );
      },
      (_) {
        _featureLogger.info(feature: 'auth', action: 'logout_succeeded');
        emit(const AuthSessionState(status: AuthSessionStatus.unauthenticated));
      },
    );
  }

  void clearFeedback() {
    if (!hasAuthFeedback(
      message: state.message,
      code: state.code,
      uiKey: state.uiKey,
    )) {
      return;
    }

    emit(state.copyWith(clearMessage: true, clearCode: true, clearUiKey: true));
  }
}
