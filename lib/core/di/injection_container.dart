import 'package:autolab_core/autolab_core.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/data/datasources/user_role_data_source.dart';
import '../../features/auth/data/datasources/user_role_data_source_impl.dart';
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
  sl.registerLazySingleton<SecureStorage>(() => core.storage);
  sl.registerLazySingleton<SessionLocalDataSource>(
        () => core.sessionLocalDataSource,
  );

  // Auth data sources
  sl.registerLazySingleton<UserRoleDataSource>(
        () => UserRoleDataSourceImpl(sl<SupabaseClient>()),
  );

  // Auth services
  sl.registerLazySingleton<LoginAttemptService>(
        () => LoginAttemptService(),
  );

  // Auth
  sl.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(
      sl<SupabaseClient>(),
      sl<GlobalErrorHandler>(),
      sl<SessionLocalDataSource>(),
      sl<UserRoleDataSource>(),
      sl<LoginAttemptService>(),
    ),
  );

  sl.registerFactory<AuthBloc>(() => AuthBloc(sl<AuthRepository>()));
}