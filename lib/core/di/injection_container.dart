import 'package:autolab_core/autolab_core.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/data/services/login_attempt_service.dart';
import '../../features/auth/repository/auth_repository.dart';

final sl = GetIt.instance;

Future<void> init({required AppConfig config}) async {
  // External
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  // Core
  final core = CoreDI.init(config: config);

  sl.registerLazySingleton<CoreDI>(() => core);
  sl.registerLazySingleton<ExceptionMapper>(() => core.exceptionMapper);
  sl.registerLazySingleton<GlobalErrorHandler>(() => core.globalErrorHandler);

  // Auth
  // NUEVO:
  // Se registra LoginAttemptService como singleton.
  // Este servicio controla:
  // - intentos fallidos
  // - bloqueo temporal
  // - aumento progresivo del tiempo
  // - reinicio del estado tras login exitoso o fin del bloqueo
  sl.registerLazySingleton<LoginAttemptService>(
        () => LoginAttemptService(),
  );

  // CAMBIO:
  // Antes AuthRepositoryImpl solo recibía:
  // - SupabaseClient
  // - GlobalErrorHandler
  //
  // Ahora también recibe:
  // - LoginAttemptService
  //
  // Esto permite que el repository pueda consultar si el usuario
  // está bloqueado, registrar fallos de login y reiniciar el estado.
  sl.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(
      sl<SupabaseClient>(),
      sl<GlobalErrorHandler>(),
      sl<LoginAttemptService>(),
    ),
  );

  sl.registerFactory<AuthBloc>(() => AuthBloc(sl<AuthRepository>()));
}