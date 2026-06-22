import 'package:autolab_customer/core/router/app_redirect_guard.dart';
import 'package:autolab_customer/features/auth/application/auth_session_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppRedirectGuard.redirectFor', () {
    const guard = AppRedirectGuard();

    test('permite quedarse en /login cuando no esta autenticado', () {
      final redirect = guard.redirectFor(
        authState: const AuthSessionState(
          status: AuthSessionStatus.unauthenticated,
        ),
        location: '/login',
      );

      expect(redirect, isNull);
    });

    test(
      'redirige a /login cuando no esta autenticado y visita ruta privada',
      () {
        final redirect = guard.redirectFor(
          authState: const AuthSessionState(
            status: AuthSessionStatus.unauthenticated,
          ),
          location: '/home',
        );

        expect(redirect, '/login');
      },
    );

    test(
      'redirige a /login cuando no esta autenticado y visita ruta dinamica',
      () {
        final redirect = guard.redirectFor(
          authState: const AuthSessionState(
            status: AuthSessionStatus.unauthenticated,
          ),
          location: '/workshops/workshop-1/appointments/new',
        );

        expect(redirect, '/login');
      },
    );

    test('permite pedir recuperacion sin estar autenticado', () {
      final redirect = guard.redirectFor(
        authState: const AuthSessionState(
          status: AuthSessionStatus.unauthenticated,
        ),
        location: '/forgot-password',
      );

      expect(redirect, isNull);
    });

    test('permite cambiar contrasena durante recovery', () {
      final redirect = guard.redirectFor(
        authState: const AuthSessionState(
          status: AuthSessionStatus.authenticated,
          userId: 'recovery-user',
          role: 'customer',
        ),
        location: '/reset-password',
      );

      expect(redirect, isNull);
    });

    test('no redirige mientras auth esta cargando', () {
      final redirect = guard.redirectFor(
        authState: const AuthSessionState(status: AuthSessionStatus.loading),
        location: '/home',
      );

      expect(redirect, isNull);
    });

    test('permite mostrar la ruta splash inicial', () {
      final redirect = guard.redirectFor(
        authState: const AuthSessionState(status: AuthSessionStatus.initial),
        location: '/startup-splash',
      );

      expect(redirect, isNull);
    });

    test(
      'redirige customer con sesion restaurada de /login a home customer',
      () {
        final redirect = guard.redirectFor(
          authState: const AuthSessionState(
            status: AuthSessionStatus.authenticated,
            userId: 'user-1',
            role: 'customer',
          ),
          location: '/login',
        );

        expect(redirect, '/home-customer');
      },
    );

    test('redirige customer con login reciente de /login a onboarding', () {
      final redirect = guard.redirectFor(
        authState: const AuthSessionState(
          status: AuthSessionStatus.authenticated,
          userId: 'user-1',
          role: 'customer',
          showCustomerOnboarding: true,
        ),
        location: '/login',
      );

      expect(redirect, '/customer-onboarding');
    });

    test('redirige customer con onboarding pendiente desde home customer', () {
      final redirect = guard.redirectFor(
        authState: const AuthSessionState(
          status: AuthSessionStatus.authenticated,
          userId: 'user-1',
          role: 'customer',
          showCustomerOnboarding: true,
        ),
        location: '/home-customer',
      );

      expect(redirect, '/customer-onboarding');
    });

    test('redirige admin autenticado de /login a /home', () {
      final redirect = guard.redirectFor(
        authState: const AuthSessionState(
          status: AuthSessionStatus.authenticated,
          userId: 'user-1',
          role: 'admin',
        ),
        location: '/login',
      );

      expect(redirect, '/home');
    });

    test('protege /home para customer', () {
      final redirect = guard.redirectFor(
        authState: const AuthSessionState(
          status: AuthSessionStatus.authenticated,
          userId: 'user-1',
          role: 'customer',
        ),
        location: '/home',
      );

      expect(redirect, '/home-customer');
    });

    test('protege /home-customer para admin', () {
      final redirect = guard.redirectFor(
        authState: const AuthSessionState(
          status: AuthSessionStatus.authenticated,
          userId: 'user-1',
          role: 'admin',
        ),
        location: '/home-customer',
      );

      expect(redirect, '/home');
    });

    test('protege onboarding de customer para admin', () {
      final redirect = guard.redirectFor(
        authState: const AuthSessionState(
          status: AuthSessionStatus.authenticated,
          userId: 'user-1',
          role: 'admin',
        ),
        location: '/customer-onboarding',
      );

      expect(redirect, '/home');
    });

    test('omite onboarding si customer ya lo vio en la sesion actual', () {
      final redirect = guard.redirectFor(
        authState: const AuthSessionState(
          status: AuthSessionStatus.authenticated,
          userId: 'user-1',
          role: 'customer',
        ),
        location: '/customer-onboarding',
      );

      expect(redirect, '/home-customer');
    });

    test('permite onboarding si viene de login reciente', () {
      final redirect = guard.redirectFor(
        authState: const AuthSessionState(
          status: AuthSessionStatus.authenticated,
          userId: 'user-1',
          role: 'customer',
          showCustomerOnboarding: true,
        ),
        location: '/customer-onboarding',
      );

      expect(redirect, isNull);
    });

    test('permite la ruta correcta para el rol autenticado', () {
      final redirect = guard.redirectFor(
        authState: const AuthSessionState(
          status: AuthSessionStatus.authenticated,
          userId: 'user-1',
          role: 'customer',
        ),
        location: '/home-customer',
      );

      expect(redirect, isNull);
    });
  });
}
