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

    test('redirige customer autenticado de /login a /home-customer', () {
      final redirect = guard.redirectFor(
        authState: const AuthSessionState(
          status: AuthSessionStatus.authenticated,
          userId: 'user-1',
          role: 'customer',
        ),
        location: '/login',
      );

      expect(redirect, '/home-customer');
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
