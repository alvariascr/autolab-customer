import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/core/router/app_router.dart';
import 'package:autolab_customer/features/auth/bloc/auth_bloc.dart';
import 'package:autolab_customer/features/auth/bloc/auth_state.dart';
import 'package:autolab_customer/features/auth/domain/entities/app_user.dart';
import 'package:autolab_customer/features/auth/repository/auth_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

class _UnusedAuthRepository implements AuthRepository {
  @override
  Future<Either<Failure, AppUser>> login(String email, String password) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, AppUser>> register(
    String name,
    String email,
    String phone,
    String password,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, Unit>> logout() {
    throw UnimplementedError();
  }

  @override
  Future<AppUser?> getCurrentUser() {
    throw UnimplementedError();
  }
}

void main() {
  group('AppRouter.redirectFor', () {
    late AuthBloc authBloc;
    late AppRouter appRouter;

    setUp(() {
      authBloc = AuthBloc(_UnusedAuthRepository());
      appRouter = AppRouter(authBloc);
    });

    tearDown(() async {
      await authBloc.close();
    });

    test('permite quedarse en /login cuando no está autenticado', () {
      final redirect = appRouter.redirectFor(
        authState: const AuthInitial(),
        location: '/login',
      );

      expect(redirect, isNull);
    });

    test('redirige a /login cuando no está autenticado y visita ruta privada', () {
      final redirect = appRouter.redirectFor(
        authState: const AuthInitial(),
        location: '/home',
      );

      expect(redirect, '/login');
    });

    test('no redirige mientras auth está cargando', () {
      final redirect = appRouter.redirectFor(
        authState: const AuthLoading(),
        location: '/home',
      );

      expect(redirect, isNull);
    });

    test('redirige customer autenticado de /login a /home-customer', () {
      final redirect = appRouter.redirectFor(
        authState: const AuthSuccess(userId: 'user-1', role: 'customer'),
        location: '/login',
      );

      expect(redirect, '/home-customer');
    });

    test('redirige admin autenticado de /login a /home', () {
      final redirect = appRouter.redirectFor(
        authState: const AuthSuccess(userId: 'user-1', role: 'admin'),
        location: '/login',
      );

      expect(redirect, '/home');
    });

    test('protege /home para customer', () {
      final redirect = appRouter.redirectFor(
        authState: const AuthSuccess(userId: 'user-1', role: 'customer'),
        location: '/home',
      );

      expect(redirect, '/home-customer');
    });

    test('protege /home-customer para admin', () {
      final redirect = appRouter.redirectFor(
        authState: const AuthSuccess(userId: 'user-1', role: 'admin'),
        location: '/home-customer',
      );

      expect(redirect, '/home');
    });

    test('permite la ruta correcta para el rol autenticado', () {
      final redirect = appRouter.redirectFor(
        authState: const AuthSuccess(userId: 'user-1', role: 'customer'),
        location: '/home-customer',
      );

      expect(redirect, isNull);
    });
  });
}
