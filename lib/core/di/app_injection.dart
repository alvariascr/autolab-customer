import 'package:autolab_core/autolab_core.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/di/auth_injection.dart';
import '../location/current_location_data_source.dart';
import '../location/geolocator_client.dart';
import '../location/location_permission_service.dart';

final GetIt sl = CoreDI.instance;

Future<void> init({required AppConfig config}) async {
  await _registerCore(config);
  _registerExternalDependencies();
  _registerFeatureDependencies();
}

Future<void> _registerCore(AppConfig config) async {
  await CoreDI.init(config: config, resetBeforeInit: true);
}

void _registerExternalDependencies() {
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  sl.registerLazySingleton<GeolocatorClient>(DefaultGeolocatorClient.new);
  sl.registerLazySingleton<LocationPermissionService>(
    GeolocatorLocationPermissionService.new,
  );
  sl.registerLazySingleton<CurrentLocationDataSource>(
    () => CurrentLocationDataSourceImpl(
      sl<GeolocatorClient>(),
      sl<GlobalErrorHandler>(),
    ),
  );
}

void _registerFeatureDependencies() {
  registerAuthDependencies(sl);
}
