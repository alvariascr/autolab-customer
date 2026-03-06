import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/repository/auth_repository.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  // Auth
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<SupabaseClient>()),
  );

  sl.registerFactory<AuthBloc>(() => AuthBloc(sl<AuthRepository>()));
}



