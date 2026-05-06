import 'package:autolab_customer/features/auth/application/auth_navigation_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('AuthNavigationController', () {
    test('navega a reset password cuando Supabase emite passwordRecovery', () {
      final navigations = <String>[];
      final controller = AuthNavigationController(navigate: navigations.add);

      controller.handleAuthState(
        const AuthState(AuthChangeEvent.passwordRecovery, null),
      );

      expect(navigations, [AuthNavigationController.resetPasswordRoute]);
    });

    test('ignora eventos que no son passwordRecovery', () {
      final navigations = <String>[];
      final controller = AuthNavigationController(navigate: navigations.add);

      controller.handleAuthState(
        const AuthState(AuthChangeEvent.signedIn, null),
      );

      expect(navigations, isEmpty);
    });
  });
}
