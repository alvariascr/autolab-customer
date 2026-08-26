import '../../features/auth/application/auth_session_state.dart';
import '../../features/auth/domain/constants/user_roles.dart';

class AppRedirectGuard {
  const AppRedirectGuard();

  String? redirectFor({
    required AuthSessionState authState,
    required String location,
  }) {
    final bool isLoggingIn = location == '/login';
    final bool isStartupSplash = location == '/startup-splash';
    final bool isCustomerOnboarding = location == '/customer-onboarding';
    final bool isPasswordRecovery =
        location == '/forgot-password' || location == '/reset-password';

    if (isStartupSplash) {
      return null;
    }

    if (isPasswordRecovery) {
      return null;
    }

    if (authState.status == AuthSessionStatus.loading ||
        authState.status == AuthSessionStatus.initial) {
      return '/startup-splash';
    }

    if (!authState.isAuthenticated) {
      return isLoggingIn ? null : '/login';
    }

    final String role = authState.role!;

    if (isLoggingIn) {
      if (role == UserRoles.admin) {
        return '/home';
      }

      return authState.showCustomerOnboarding
          ? '/customer-onboarding'
          : '/home-customer';
    }

    if (role == UserRoles.customer && location == '/home') {
      return '/home-customer';
    }

    if (role == UserRoles.customer &&
        authState.showCustomerOnboarding &&
        !isCustomerOnboarding) {
      return '/customer-onboarding';
    }

    if (role == UserRoles.customer &&
        isCustomerOnboarding &&
        !authState.showCustomerOnboarding) {
      return '/home-customer';
    }

    if (role == UserRoles.admin &&
        (location == '/home-customer' ||
            location == '/cart' ||
            isCustomerOnboarding)) {
      return '/home';
    }

    return null;
  }
}
