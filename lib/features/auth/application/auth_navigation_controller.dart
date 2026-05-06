import 'package:supabase_flutter/supabase_flutter.dart';

class AuthNavigationController {
  AuthNavigationController({required void Function(String location) navigate})
    : _navigate = navigate;

  static const resetPasswordRoute = '/reset-password';

  final void Function(String location) _navigate;

  void handleAuthState(AuthState data) {
    if (data.event != AuthChangeEvent.passwordRecovery) return;

    _navigate(resetPasswordRoute);
  }
}
