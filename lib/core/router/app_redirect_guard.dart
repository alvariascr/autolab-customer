import '../../features/auth/application/auth_session_state.dart';
import '../../features/auth/domain/constants/user_roles.dart';

class AppRedirectGuard {
  const AppRedirectGuard();

  String? redirectFor({
    required AuthSessionState authState,
    required String location,
  }) {
    final bool isLoggingIn = location == '/login';
    final bool isPasswordRecovery =
        location == '/forgot-password' || location == '/reset-password';

    if (isPasswordRecovery) {
      return null;
    }

    if (authState.status == AuthSessionStatus.loading ||
        authState.status == AuthSessionStatus.initial) {
      return null;
    }

    if (!authState.isAuthenticated) {
      return isLoggingIn ? null : '/login';
    }

    final String role = authState.role!;

    if (isLoggingIn) {
      return role == UserRoles.admin ? '/home' : '/home-customer';
    }

    if (role == UserRoles.customer && location == '/home') {
      return '/home-customer';
    }

    if (role == UserRoles.admin && location == '/home-customer') {
      return '/home';
    }

    return null;
  }
}
