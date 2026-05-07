import 'package:supabase_flutter/supabase_flutter.dart';

class AuthNavigationController {
  AuthNavigationController({
    required void Function(String location) navigate,
    Future<void> Function()? clearSession,
  }) : _navigate = navigate,
       _clearSession = clearSession;

  static const loginRoute = '/login';
  static const emailConfirmedLoginRoute = '/login?emailConfirmed=true';
  static const resetPasswordRoute = '/reset-password';

  static const _loginCallbackScheme = 'autolab';
  static const _loginCallbackHost = 'login-callback';
  static const _emailConfirmedPath = '/email-confirmed';

  final void Function(String location) _navigate;
  final Future<void> Function()? _clearSession;

  void handleAuthState(AuthState data) {
    if (data.event != AuthChangeEvent.passwordRecovery) return;

    _navigate(resetPasswordRoute);
  }

  Future<void> handleAppLink(Uri uri) async {
    if (!_isEmailConfirmedCallback(uri)) return;

    await _clearSession?.call();
    _navigate(emailConfirmedLoginRoute);
  }

  bool _isEmailConfirmedCallback(Uri uri) {
    return uri.scheme == _loginCallbackScheme &&
        uri.host == _loginCallbackHost &&
        uri.path == _emailConfirmedPath;
  }
}
