import 'package:get_it/get_it.dart';

import '../../common/bloc/authentication_cubit.dart';
import '../../data/auth/datasources/auth_local_datasource.dart';
import '../../data/auth/repositories/auth_repository_impl.dart';
import '../../domain/auth/repositories/auth_repository.dart';
import '../../domain/auth/usecases/get_auth_status.dart';
import '../../domain/auth/usecases/login.dart';
import '../../domain/auth/usecases/logout.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ---------------------------
  // DataSources
  // ---------------------------
  sl.registerLazySingleton<AuthLocalDataSource>(() => AuthLocalDataSource());

  // ---------------------------
  // Repositories
  // ---------------------------
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<AuthLocalDataSource>()),
  );

  // ---------------------------
  // UseCases
  // ---------------------------
  sl.registerLazySingleton(() => GetAuthStatus(sl<AuthRepository>()));
  sl.registerLazySingleton(() => Login(sl<AuthRepository>()));
  sl.registerLazySingleton(() => Logout(sl<AuthRepository>()));

  // ---------------------------
  // Cubits / Bloc
  // ---------------------------
  sl.registerLazySingleton(
    () => AuthenticationCubit(
      getAuthStatus: sl<GetAuthStatus>(),
      login: sl<Login>(),
      logout: sl<Logout>(),
    ),
  );
}