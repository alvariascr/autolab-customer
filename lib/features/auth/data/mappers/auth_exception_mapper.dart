import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/features/auth/domain/errors/auth_error_catalog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthExceptionFlow { login, register, registerPrecheck }

final class AuthExceptionMapping {
  const AuthExceptionMapping({
    required this.failure,
    required this.classification,
  });

  final Failure failure;
  final String classification;
}

final class AuthExceptionMapper {
  const AuthExceptionMapper();

  AuthExceptionMapping? map(
    AuthException error,
    StackTrace stackTrace, {
    required AuthExceptionFlow flow,
  }) {
    if (error is AuthWeakPasswordException) {
      return _mapping(
        AuthFailure.fromErrorItem(
          AuthErrorCatalog.weakPassword,
          cause: error,
          stackTrace: stackTrace,
        ),
        'weak_password',
      );
    }

    if (error is AuthInvalidJwtException ||
        error is AuthSessionMissingException) {
      return _mapping(
        AuthFailure.fromErrorItem(
          AuthErrorCatalog.sessionExpired,
          cause: error,
          stackTrace: stackTrace,
        ),
        'session_expired',
      );
    }

    if (error is AuthRetryableFetchException) {
      final statusCode = _parseStatusCode(error.statusCode);
      if (statusCode != null && statusCode >= 500) {
        return _mapping(
          ServerFailure.fromErrorItem(
            ErrorCatalog.serverError,
            cause: error,
            stackTrace: stackTrace,
          ),
          'retryable_server_error',
        );
      }

      return _mapping(
        NetworkFailure.fromErrorItem(
          ErrorCatalog.networkUnavailable,
          cause: error,
          stackTrace: stackTrace,
        ),
        'retryable_network_error',
      );
    }

    if (error is AuthApiException) {
      final mapped = _mapApiException(error, stackTrace, flow: flow);
      if (mapped != null) {
        return mapped;
      }
    }

    final statusCode = _parseStatusCode(error.statusCode);
    if (statusCode != null && statusCode >= 500) {
      return _mapping(
        ServerFailure.fromErrorItem(
          ErrorCatalog.serverError,
          cause: error,
          stackTrace: stackTrace,
        ),
        'server_error',
      );
    }

    return null;
  }

  bool isRegisterAvailabilitySignal(AuthException error) {
    if (error is! AuthApiException) {
      return false;
    }

    final statusCode = _parseStatusCode(error.statusCode);
    return error.code == null && (statusCode == 400 || statusCode == 401);
  }

  Map<String, Object?> buildLogContext(
    AuthException error, {
    required AuthExceptionFlow flow,
    Failure? failure,
    String? email,
    String? resolution,
    String? classification,
  }) {
    return {
      'flow': flow.name,
      ...?_emailContext(email),
      'authExceptionType': error.runtimeType.toString(),
      'authStatusCode': error.statusCode ?? 'none',
      'authCode': error.code ?? 'none',
      ...?_singleValueContext('classification', classification),
      ...?_singleValueContext('uiKey', failure?.uiKey),
      ...?_singleValueContext('resolution', resolution),
    };
  }

  AuthExceptionMapping? _mapApiException(
    AuthApiException error,
    StackTrace stackTrace, {
    required AuthExceptionFlow flow,
  }) {
    final errorCode = error.code;
    final statusCode = _parseStatusCode(error.statusCode);

    switch (errorCode) {
      case _SupabaseAuthCodes.emailNotConfirmed:
        return _mapping(
          AuthFailure.fromErrorItem(
            flow == AuthExceptionFlow.registerPrecheck
                ? AuthErrorCatalog.emailNotConfirmedRegister
                : AuthErrorCatalog.unconfirmedEmail,
            cause: error,
            stackTrace: stackTrace,
          ),
          'email_not_confirmed',
        );
      case _SupabaseAuthCodes.emailExists:
      case _SupabaseAuthCodes.userAlreadyExists:
      case _SupabaseAuthCodes.identityAlreadyExists:
      case _SupabaseAuthCodes.phoneExists:
      case _SupabaseAuthCodes.conflict:
        return _mapping(
          AuthFailure.fromErrorItem(
            flow == AuthExceptionFlow.register
                ? AuthErrorCatalog.emailAlreadyRegistered
                : AuthErrorCatalog.accountAlreadyExists,
            cause: error,
            stackTrace: stackTrace,
          ),
          'account_exists',
        );
      case _SupabaseAuthCodes.weakPassword:
        return _mapping(
          AuthFailure.fromErrorItem(
            AuthErrorCatalog.weakPassword,
            cause: error,
            stackTrace: stackTrace,
          ),
          'weak_password',
        );
      case _SupabaseAuthCodes.requestTimeout:
      case _SupabaseAuthCodes.hookTimeout:
      case _SupabaseAuthCodes.hookTimeoutAfterRetry:
        return _mapping(
          TimeoutFailure.fromErrorItem(
            ErrorCatalog.requestTimeout,
            cause: error,
            stackTrace: stackTrace,
          ),
          'request_timeout',
        );
      case _SupabaseAuthCodes.overRequestRateLimit:
      case _SupabaseAuthCodes.overEmailSendRateLimit:
      case _SupabaseAuthCodes.overSmsSendRateLimit:
        return _mapping(
          AuthFailure.fromErrorItem(
            flow == AuthExceptionFlow.register
                ? AuthErrorCatalog.registerRateLimit
                : AuthErrorCatalog.authRateLimit,
            cause: error,
            stackTrace: stackTrace,
          ),
          'rate_limited',
        );
      default:
        break;
    }

    if (flow == AuthExceptionFlow.login && _isLoginInvalidCredentials(error)) {
      return _mapping(
        AuthFailure.fromErrorItem(
          AuthErrorCatalog.invalidCredentials,
          cause: error,
          stackTrace: stackTrace,
        ),
        'invalid_credentials',
      );
    }

    if (statusCode != null && statusCode == 429) {
      return _mapping(
        AuthFailure.fromErrorItem(
          flow == AuthExceptionFlow.register
              ? AuthErrorCatalog.registerRateLimit
              : AuthErrorCatalog.authRateLimit,
          cause: error,
          stackTrace: stackTrace,
        ),
        'rate_limited',
      );
    }

    if (statusCode != null && statusCode >= 500) {
      return _mapping(
        ServerFailure.fromErrorItem(
          ErrorCatalog.serverError,
          cause: error,
          stackTrace: stackTrace,
        ),
        'server_error',
      );
    }

    return null;
  }

  bool _isLoginInvalidCredentials(AuthApiException error) {
    final statusCode = _parseStatusCode(error.statusCode);
    return error.code == null && (statusCode == 400 || statusCode == 401);
  }

  int? _parseStatusCode(String? statusCode) {
    if (statusCode == null || statusCode.isEmpty) {
      return null;
    }

    return int.tryParse(statusCode);
  }

  AuthExceptionMapping _mapping(Failure failure, String classification) {
    return AuthExceptionMapping(
      failure: failure,
      classification: classification,
    );
  }

  Map<String, Object?>? _emailContext(String? email) {
    return _singleValueContext('email', email);
  }

  Map<String, Object?>? _singleValueContext(String key, Object? value) {
    if (value == null) {
      return null;
    }

    return {key: value};
  }
}

final class _SupabaseAuthCodes {
  static const emailNotConfirmed = 'email_not_confirmed';
  static const emailExists = 'email_exists';
  static const userAlreadyExists = 'user_already_exists';
  static const identityAlreadyExists = 'identity_already_exists';
  static const phoneExists = 'phone_exists';
  static const conflict = 'conflict';
  static const weakPassword = 'weak_password';
  static const requestTimeout = 'request_timeout';
  static const hookTimeout = 'hook_timeout';
  static const hookTimeoutAfterRetry = 'hook_timeout_after_retry';
  static const overRequestRateLimit = 'over_request_rate_limit';
  static const overEmailSendRateLimit = 'over_email_send_rate_limit';
  static const overSmsSendRateLimit = 'over_sms_send_rate_limit';
}
