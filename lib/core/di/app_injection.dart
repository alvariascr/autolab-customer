import 'package:autolab_core/autolab_core.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/di/auth_injection.dart';
import '../../features/map/presentation/cubit/map_cubit.dart';
import '../../features/workshops/data/datasources/workshop_remote_data_source.dart';
import '../../features/workshops/data/datasources/workshop_remote_data_source_impl.dart';
import '../../features/workshops/data/repositories/workshop_repository_impl.dart';
import '../../features/workshops/domain/repositories/workshop_repository.dart';
import '../location/current_location_data_source.dart';
import '../location/geocoding_client.dart';
import '../location/geolocator_client.dart';
import '../location/location_cubit.dart';
import '../location/location_flow_recovery_service.dart';
import '../location/location_permission_client.dart';
import '../location/location_permission_service.dart';
import '../location/location_place_resolver.dart';

final GetIt sl = CoreDI.instance;

Future<void> init({required AppConfig config}) async {
  await _registerCore(config);
  await _registerExternalDependencies();
  _registerFeatureDependencies();
}

Future<void> _registerCore(AppConfig config) async {
  await CoreDI.init(config: config, resetBeforeInit: true);
}

Future<void> _registerExternalDependencies() async {
  final prefs = await SharedPreferences.getInstance();

  sl.registerSingleton<SharedPreferences>(prefs);
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  sl.registerLazySingleton<GeolocatorClient>(DefaultGeolocatorClient.new);
  sl.registerLazySingleton<GeocodingClient>(DefaultGeocodingClient.new);
  sl.registerLazySingleton<LocationFlowRecoveryService>(
    () => SharedPrefsLocationFlowRecoveryService(sl<SharedPreferences>()),
  );
  sl.registerLazySingleton<LocationPermissionClient>(
    DefaultLocationPermissionClient.new,
  );
  sl.registerLazySingleton<LocationPermissionService>(
    () => GeolocatorLocationPermissionService(sl<LocationPermissionClient>()),
  );
  sl.registerLazySingleton<CurrentLocationDataSource>(
    () => CurrentLocationDataSourceImpl(
      sl<GeolocatorClient>(),
      sl<GlobalErrorHandler>(),
    ),
  );
  sl.registerLazySingleton<LocationPlaceResolver>(
    () => GeocodingLocationPlaceResolver(sl<GeocodingClient>()),
  );
  sl.registerLazySingleton<LocationCubit>(
    () => LocationCubit(
      sl<LocationPermissionService>(),
      sl<CurrentLocationDataSource>(),
      sl<LocationPlaceResolver>(),
      flowRecoveryService: sl<LocationFlowRecoveryService>(),
      errorHandler: sl<GlobalErrorHandler>(),
    ),
  );
}

void _registerFeatureDependencies() {
  registerAuthDependencies(sl);
  sl.registerLazySingleton<WorkshopRemoteDataSource>(
    () => WorkshopRemoteDataSourceImpl(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<WorkshopRepository>(
    () => WorkshopRepositoryImpl(
      remoteDataSource: sl<WorkshopRemoteDataSource>(),
      errorHandler: sl<GlobalErrorHandler>(),
    ),
  );
  sl.registerFactory<MapCubit>(() => MapCubit(sl<WorkshopRepository>()));
}
