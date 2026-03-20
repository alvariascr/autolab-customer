import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/constants/user_roles.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/failures/auth_rate_limit_failure.dart';
import '../../repository/auth_repository.dart';
import '../services/login_attempt_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  // Cliente de Supabase para autenticación
  final SupabaseClient client;

  // Manejador global de errores del proyecto
  final GlobalErrorHandler globalErrorHandler;

  // Servicio encargado de controlar intentos de login
  final LoginAttemptService loginAttemptService;

  // Constructor con inyección de dependencias
  AuthRepositoryImpl(
    this.client,
    this.globalErrorHandler,
    this.loginAttemptService,
  );

  // Función para formatear duración
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }
  // Obtiene el rol del usuario desde la tabla user_profiles
  Future<String> _getUserRole(String userId) async {
    final response = await client
        .from('user_profiles')
        .select('role')
        .eq('user_id', userId)
        .maybeSingle();
    // Si no existe el perfil
    if (response == null) {
      throw const AuthFailure(message: 'Perfil de usuario no encontrado');
    }
    final role = response['role'] as String?;

    // Validaciones del rol
    if (role == null || role.isEmpty) {
      throw AuthFailure(message: 'Rol no definido para el usuario');
    }
    if (!UserRoles.isValid(role)) {
      throw const AuthFailure(message: 'Rol no autorizado');
    }

    return role;
  }

  @override
  Future<Either<Failure, AppUser>> login(String email, String password) async {
    // Limpieza de datos
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    try {
      // Verifica si el usuario está bloqueado
      final state = await loginAttemptService.getState(cleanEmail);
      if (state.isBlocked) {
        final remaining = state.remainingTime;
        // Si está bloqueado, no intenta login
        return Left(
          AuthRateLimitFailure(
            remaining: remaining,
            message:
                'Has excedido el número de intentos permitidos. '
                'Intenta nuevamente en ${_formatDuration(remaining)}.',
          ),
        );
      }
      // Intenta autenticarse con Supabase
      final res = await client.auth.signInWithPassword(
        email: cleanEmail,
        password: cleanPassword,
      );

      final user = res.user;
      // Validación de respuesta
      if (user == null) {
        return const Left(
          AuthFailure(message: 'Respuesta inválida: usuario no disponible'),
        );
      }
      //Obtiene el rol del usuario
      final role = await _getUserRole(user.id);
      // Si login es exitoso → reinicia intentos
      await loginAttemptService.registerSuccess(cleanEmail);
      // Retorna usuario autenticado
      return Right(AppUser(id: user.id, email: user.email, role: role));
    } on AuthFailure catch (failure) {
      return Left(failure);
    } on AuthException catch (e, st) {
      final msg = e.message.toLowerCase();

      // Si las credenciales son incorrectas
      if (msg.contains('invalid login credentials')) {
        // Registra intento fallido
        final updatedState = await loginAttemptService.registerFailure(
          cleanEmail,
        );
        // Si ya llegó al límite → bloquear
        if (updatedState.isBlocked) {
          final remaining = updatedState.remainingTime;

          return Left(
            AuthRateLimitFailure(
              remaining: remaining,
              message:
                  'Has excedido el número de intentos permitidos. '
                  'Intenta nuevamente en ${_formatDuration(remaining)}.',
            ),
          );
        }
        // Si aún no llega al límite
        return const Left(
          AuthFailure(message: 'Correo o contraseña incorrectos'),
        );
      }
      // Otros errores manejados globalmente
      final failure = globalErrorHandler.handle(e, st);
      return Left(failure);
    } catch (e, st) {
      final failure = globalErrorHandler.handle(e, st);
      return Left(failure);
    }
  }

  @override
  Future<Either<Failure, AppUser>> register(
    String email,
    String password,
  ) async {
    try {
      final res = await client.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final user = res.user;
      if (user == null) {
        globalErrorHandler.logger.w(
          'Registro fallido: respuesta inválida, usuario no disponible',
        );

        return const Left(
          AuthFailure(message: 'Respuesta inválida: usuario no disponible'),
        );
      }
      return Right(
        AppUser(id: user.id, email: user.email, role: UserRoles.customer),
      );
    } on AuthFailure catch (failure) {
      return Left(failure);
    } on AuthException catch (e, st) {
      final msg = e.message.toLowerCase();
      if (msg.contains('already registered')) {
        globalErrorHandler.logger.w(
          'Intento de registro con correo ya existente',
          error: e,
          stackTrace: st,
        );

        return const Left(
          AuthFailure(message: 'Este correo ya se encuentra registrado'),
        );
      }

      final failure = globalErrorHandler.handle(e, st);
      return Left(failure);
    } catch (e, st) {
      final failure = globalErrorHandler.handle(e, st);
      return Left(failure);
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      await client.auth.signOut();
      return const Right(unit);
    } catch (e, st) {
      final failure = globalErrorHandler.handle(e, st);
      return Left(failure);
    }
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    try {
      final role = await _getUserRole(user.id);

      return AppUser(id: user.id, email: user.email, role: role);
    } on AuthFailure catch (failure, st) {
      globalErrorHandler.logger.e(
        'No fue posible restaurar la sesión por problema de rol/perfil',
        error: failure,
        stackTrace: st,
      );
      return null;
    } catch (e, st) {
      globalErrorHandler.logger.e(
        'Error restaurando sesión del usuario',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }
}
