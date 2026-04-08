import 'package:autolab_core/autolab_core.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../location/location_permission_service.dart';
import '../../features/auth/di/auth_injection.dart';

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
  sl.registerLazySingleton<LocationPermissionService>(
    GeolocatorLocationPermissionService.new,
  );
}

void _registerFeatureDependencies() {
  registerAuthDependencies(sl);
}
