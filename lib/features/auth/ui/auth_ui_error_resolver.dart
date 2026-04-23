import '../../../l10n/app_localizations.dart';
import '../domain/errors/auth_error_catalog.dart';

final class AuthUiErrorResolver {
  const AuthUiErrorResolver._();

  static String resolve({
    required AppLocalizations l10n,
    String? code,
    String? uiKey,
    String? message,
    Duration? remaining,
  }) {
    final fallbackMessage = message == null || message == code ? null : message;
    final resolvedUiKey = uiKey;

    if (resolvedUiKey != null && resolvedUiKey.isNotEmpty) {
      return switch (resolvedUiKey) {
        final value when value == AuthErrorCatalog.invalidCredentials.uiKey =>
          l10n.authErrorInvalidCredentials,
        final value when value == AuthErrorCatalog.sessionExpired.uiKey =>
          l10n.authErrorSessionExpired,
        final value when value == AuthErrorCatalog.unauthorized.uiKey =>
          l10n.authErrorUnauthorized,
        final value when value == AuthErrorCatalog.invalidAuthResponse.uiKey =>
          l10n.authErrorInvalidAuthResponse,
        final value when value == AuthErrorCatalog.userProfileNotFound.uiKey =>
          l10n.authErrorUserProfileNotFound,
        final value when value == AuthErrorCatalog.undefinedUserRole.uiKey =>
          l10n.authErrorUndefinedUserRole,
        final value when value == AuthErrorCatalog.unconfirmedEmail.uiKey =>
          l10n.authErrorUnconfirmedEmail,
        final value
            when value == AuthErrorCatalog.emailAlreadyRegistered.uiKey =>
          l10n.authErrorEmailAlreadyRegistered,
        final value
            when value == AuthErrorCatalog.invalidRegisterResponse.uiKey =>
          l10n.authErrorInvalidRegisterResponse,
        final value when value == AuthErrorCatalog.authRateLimit.uiKey =>
          l10n.authErrorRateLimit(_formatRemaining(l10n, remaining)),
        final value when value == AuthErrorCatalog.invalidEmail.uiKey =>
          l10n.authErrorInvalidEmail,
        final value when value == AuthErrorCatalog.weakPassword.uiKey =>
          l10n.authErrorWeakPassword,
        final value
            when value == AuthErrorCatalog.emailNotConfirmedRegister.uiKey =>
          l10n.authErrorEmailNotConfirmedRegister,
        final value when value == AuthErrorCatalog.accountAlreadyExists.uiKey =>
          l10n.authErrorAccountAlreadyExists,
        final value when value == AuthErrorCatalog.registerRateLimit.uiKey =>
          l10n.authErrorRegisterRateLimit,
        final value
            when value == AuthErrorCatalog.registerUnexpectedError.uiKey =>
          l10n.authErrorRegisterUnexpected,
        final value when value == AuthErrorCatalog.sessionRestoreFailed.uiKey =>
          l10n.authErrorSessionRestoreFailed,
        final value
            when value == AuthErrorCatalog.localSessionRecoveryFailed.uiKey =>
          l10n.authErrorLocalSessionRecoveryFailed,
        _ => fallbackMessage ?? l10n.authErrorFallback,
      };
    }

    if (code == null || code.isEmpty) {
      return fallbackMessage ?? l10n.authErrorFallback;
    }

    return switch (code) {
      final value when value == AuthErrorCatalog.invalidCredentials.code =>
        l10n.authErrorInvalidCredentials,
      final value when value == AuthErrorCatalog.unconfirmedEmail.code =>
        l10n.authErrorUnconfirmedEmail,
      final value when value == AuthErrorCatalog.emailAlreadyRegistered.code =>
        l10n.authErrorEmailAlreadyRegistered,
      final value
          when value == AuthErrorCatalog.emailNotConfirmedRegister.code =>
        l10n.authErrorEmailNotConfirmedRegister,
      final value when value == AuthErrorCatalog.accountAlreadyExists.code =>
        l10n.authErrorAccountAlreadyExists,
      final value when value == AuthErrorCatalog.authRateLimit.code =>
        l10n.authErrorRateLimit(_formatRemaining(l10n, remaining)),
      _ => fallbackMessage ?? l10n.authErrorFallback,
    };
  }

  static String _formatRemaining(AppLocalizations l10n, Duration? remaining) {
    if (remaining == null) {
      return l10n.authErrorRateLimitFallbackRemaining;
    }

    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;

    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }

    return '${seconds}s';
  }
}
