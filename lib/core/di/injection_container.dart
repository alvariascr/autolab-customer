import 'package:autolab_core/autolab_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/repository/auth_repository.dart';

final sl = GetIt.instance;

Future<void> init({required AppConfig config}) async {
  // External
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  // Core
  final core = CoreDI.init(config: config);

  sl.registerLazySingleton<CoreDI>(() => core);
  sl.registerLazySingleton<ExceptionMapper>(() => core.exceptionMapper);
  sl.registerLazySingleton<GlobalErrorHandler>(() => core.globalErrorHandler);

  // Secure storage
  sl.registerLazySingleton<SecureStorage>(
    () => SecureStorageImpl(sl<FlutterSecureStorage>()),
  );

  sl.registerLazySingleton<SessionLocalDataSource>(
    () => SessionLocalDataSourceImpl(sl<SecureStorage>()),
  );

  // Auth
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      sl<SupabaseClient>(),
      sl<GlobalErrorHandler>(),
      sl<SessionLocalDataSource>(),
    ),
  );

  sl.registerFactory<AuthBloc>(() => AuthBloc(sl<AuthRepository>()));
}
