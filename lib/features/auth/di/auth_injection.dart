import 'package:autolab_core/autolab_core.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../application/auth_session_cubit.dart';
import '../data/datasources/session_local_data_source.dart';
import '../data/datasources/session_local_data_source_impl.dart';
import '../data/datasources/user_role_data_source.dart';
import '../data/datasources/user_role_data_source_impl.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/services/auth_session_recovery_service.dart';
import '../data/services/auth_session_storage_service.dart';
import '../data/services/login_attempt_service.dart';
import '../repository/auth_repository.dart';

void registerAuthDependencies(GetIt sl) {
  sl.registerLazySingleton<UserRoleDataSource>(
    () => UserRoleDataSourceImpl(sl<SupabaseClient>()),
  );

  sl.registerLazySingleton<LoginAttemptService>(
    () => LoginAttemptService(sl<SharedPreferences>()),
  );

  sl.registerLazySingleton<SessionLocalDataSource>(
    () => SessionLocalDataSourceImpl(sl<SecureStorage>()),
  );

  sl.registerLazySingleton<AuthSessionStorageService>(
    () => AuthSessionStorageService(sl<SessionLocalDataSource>()),
  );

  sl.registerLazySingleton<AuthSessionRecoveryService>(
    () => AuthSessionRecoveryService(
      client: sl<SupabaseClient>(),
      sessionStorageService: sl<AuthSessionStorageService>(),
      userRoleDataSource: sl<UserRoleDataSource>(),
      errorHandler: sl<GlobalErrorHandler>(),
    ),
  );

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      sl<SupabaseClient>(),
      sl<GlobalErrorHandler>(),
      sl<UserRoleDataSource>(),
      sl<LoginAttemptService>(),
      sl<AuthSessionStorageService>(),
      sl<AuthSessionRecoveryService>(),
    ),
  );

  sl.registerLazySingleton<AuthSessionCubit>(
    () => AuthSessionCubit(sl<AuthRepository>()),
  );
}
