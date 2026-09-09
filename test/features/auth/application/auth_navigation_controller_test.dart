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

    test(
      'navega al login cuando recibe el callback de correo confirmado',
      () async {
        final navigations = <String>[];
        var sessionCleared = false;
        final controller = AuthNavigationController(
          navigate: navigations.add,
          clearSession: () async {
            sessionCleared = true;
          },
        );

        await controller.handleAppLink(
          Uri.parse('autolab://login-callback/email-confirmed'),
        );

        expect(sessionCleared, true);
        expect(navigations, [
          AuthNavigationController.emailConfirmedLoginRoute,
        ]);
        // El login por defecto muestra el formulario de Registro; sin
        // mode=login esta ruta caería ahí en vez de Login, y el mensaje de
        // "correo confirmado" (que exige estar en modo Login) nunca se vería.
        expect(
          AuthNavigationController.emailConfirmedLoginRoute,
          '/login?emailConfirmed=true&mode=login',
        );
      },
    );

    test('ignora app links que no son de confirmacion de correo', () async {
      final navigations = <String>[];
      var sessionCleared = false;
      final controller = AuthNavigationController(
        navigate: navigations.add,
        clearSession: () async {
          sessionCleared = true;
        },
      );

      await controller.handleAppLink(
        Uri.parse('autolab://login-callback/reset-password'),
      );

      expect(sessionCleared, false);
      expect(navigations, isEmpty);
    });
  });
}
