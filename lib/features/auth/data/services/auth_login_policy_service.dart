import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/features/auth/domain/errors/auth_error_catalog.dart';
import 'package:autolab_customer/features/auth/domain/failures/auth_rate_limit_failure.dart';

import 'login_attempt_service.dart';

class AuthLoginPolicyService {
  AuthLoginPolicyService(this._loginAttemptService);

  final LoginAttemptService _loginAttemptService;

  Future<Failure?> getBlockFailure(String email) async {
    final attemptState = await _loginAttemptService.getState(email);
    if (!attemptState.isBlocked) {
      return null;
    }

    return _createAuthRateLimitFailure(attemptState.remainingTime);
  }

  Future<Failure> registerInvalidCredentials(
    String email, {
    required Object cause,
    required StackTrace stackTrace,
  }) async {
    final updatedState = await _loginAttemptService.registerFailure(email);
    if (updatedState.isBlocked) {
      return _createAuthRateLimitFailure(
        updatedState.remainingTime,
        cause: cause,
        stackTrace: stackTrace,
      );
    }

    return AuthFailure.fromErrorItem(
      AuthErrorCatalog.invalidCredentials,
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  Future<void> registerSuccess(String email) {
    return _loginAttemptService.registerSuccess(email);
  }

  AuthRateLimitFailure _createAuthRateLimitFailure(
    Duration remaining, {
    Object? cause,
    StackTrace? stackTrace,
  }) {
    return AuthRateLimitFailure(
      remaining: remaining,
      code: AuthErrorCatalog.authRateLimit.code,
      uiKey: AuthErrorCatalog.authRateLimit.uiKey,
      message: AuthErrorCatalog.authRateLimit.code,
      cause: cause,
      stackTrace: stackTrace,
    );
  }
}
