import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/core/logging/feature_logger.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../application/auth_session_cubit.dart';
import '../data/datasources/session_local_data_source.dart';
import '../data/datasources/session_local_data_source_impl.dart';
import '../data/datasources/user_role_data_source.dart';
import '../data/datasources/user_role_data_source_impl.dart';
import '../data/mappers/auth_exception_mapper.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/services/auth_local_session_recovery_service.dart';
import '../data/services/auth_login_policy_service.dart';
import '../data/services/auth_session_recovery_service.dart';
import '../data/services/auth_session_storage_service.dart';
import '../data/services/auth_supabase_session_sync_service.dart';
import '../data/services/login_attempt_service.dart';
import '../repository/auth_repository.dart';

void registerAuthDependencies(GetIt sl) {
  sl.registerLazySingleton<UserRoleDataSource>(
    () => UserRoleDataSourceImpl(sl<SupabaseClient>()),
  );

  sl.registerLazySingleton<LoginAttemptService>(
    () => LoginAttemptService(sl<SharedPreferences>()),
  );

  sl.registerLazySingleton<AuthExceptionMapper>(
    () => const AuthExceptionMapper(),
  );

  sl.registerLazySingleton<AuthLoginPolicyService>(
    () => AuthLoginPolicyService(sl<LoginAttemptService>()),
  );

  sl.registerLazySingleton<SessionLocalDataSource>(
    () => SessionLocalDataSourceImpl(sl<SecureStorage>()),
  );

  sl.registerLazySingleton<AuthSessionStorageService>(
    () => AuthSessionStorageService(sl<SessionLocalDataSource>()),
  );

  sl.registerLazySingleton<AuthSupabaseSessionSyncService>(
    () => AuthSupabaseSessionSyncService(
      sessionStorageService: sl<AuthSessionStorageService>(),
      userRoleDataSource: sl<UserRoleDataSource>(),
      featureLogger: sl<FeatureLogger>(),
    ),
  );

  sl.registerLazySingleton<AuthLocalSessionRecoveryService>(
    () => AuthLocalSessionRecoveryService(
      sessionStorageService: sl<AuthSessionStorageService>(),
      featureLogger: sl<FeatureLogger>(),
    ),
  );

  sl.registerLazySingleton<AuthSessionRecoveryService>(
    () => AuthSessionRecoveryService(
      client: sl<SupabaseClient>(),
      sessionStorageService: sl<AuthSessionStorageService>(),
      supabaseSessionSyncService: sl<AuthSupabaseSessionSyncService>(),
      localSessionRecoveryService: sl<AuthLocalSessionRecoveryService>(),
      featureLogger: sl<FeatureLogger>(),
    ),
  );

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      sl<SupabaseClient>(),
      sl<GlobalErrorHandler>(),
      sl<UserRoleDataSource>(),
      sl<AuthLoginPolicyService>(),
      sl<AuthSessionStorageService>(),
      sl<AuthSessionRecoveryService>(),
      sl<FeatureLogger>(),
      sl<AuthExceptionMapper>(),
    ),
  );

  sl.registerLazySingleton<AuthSessionCubit>(
    () => AuthSessionCubit(sl<AuthRepository>(), sl<FeatureLogger>()),
  );
}
