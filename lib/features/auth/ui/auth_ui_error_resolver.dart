import '../../../l10n/app_localizations.dart';
import '../domain/errors/auth_error_catalog.dart';

final class AuthUiErrorResolver {
  const AuthUiErrorResolver._();

  static String resolve({
    required AppLocalizations l10n,
    String? code,
    String? message,
    Duration? remaining,
  }) {
    if (code == null || code.isEmpty) {
      return message ?? l10n.authErrorFallback;
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
      _ => message ?? l10n.authErrorFallback,
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
