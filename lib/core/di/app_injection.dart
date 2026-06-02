import 'package:autolab_core/autolab_core.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/appointments/data/datasources/appointment_remote_data_source.dart';
import '../../features/appointments/data/datasources/appointment_remote_data_source_impl.dart';
import '../../features/appointments/data/repositories/appointment_repository_impl.dart';
import '../../features/appointments/domain/repositories/appointment_repository.dart';
import '../../features/appointments/presentation/cubit/create_appointment_cubit.dart';
import '../../features/appointments/presentation/cubit/my_appointments_cubit.dart';
import '../../features/auth/di/auth_injection.dart';
import '../../features/home/application/recent_searches_store.dart';
import '../../features/map/presentation/cubit/map_cubit.dart';
import '../../features/products/data/datasources/product_remote_data_source.dart';
import '../../features/products/data/datasources/product_remote_data_source_impl.dart';
import '../../features/products/data/repositories/product_repository_impl.dart';
import '../../features/products/domain/repositories/product_repository.dart';
import '../../features/products/domain/usecases/get_additional_products_by_workshop.dart';
import '../../features/products/domain/usecases/get_schedulable_services_by_workshop.dart';
import '../../features/workshops/application/appointment_cubit.dart';
import '../../features/workshops/application/workshop_discovery_query_store.dart';
import '../../features/workshops/data/datasources/appointment_booking_remote_data_source.dart';
import '../../features/workshops/data/datasources/workshop_remote_data_source.dart';
import '../../features/workshops/data/datasources/workshop_remote_data_source_impl.dart';
import '../../features/workshops/data/repositories/appointment_booking_repository_impl.dart';
import '../../features/workshops/data/repositories/workshop_repository_impl.dart';
import '../../features/workshops/domain/repositories/appointment_booking_repository.dart';
import '../../features/workshops/domain/repositories/workshop_repository.dart';
import '../../features/workshops/domain/usecases/book_service_appointment.dart';
import '../../features/workshops/domain/usecases/get_booked_appointment_slots.dart';
import '../../features/workshops/domain/usecases/get_customer_vehicle_by_plate.dart';
import '../../features/workshops/domain/usecases/get_customer_vehicles.dart';
import '../../features/workshops/domain/usecases/is_appointment_slot_available.dart';
import '../location/current_location_data_source.dart';
import '../location/geocoding_client.dart';
import '../location/geolocator_client.dart';
import '../location/location_cubit.dart';
import '../location/location_flow_recovery_service.dart';
import '../location/location_permission_client.dart';
import '../location/location_permission_service.dart';
import '../location/location_place_resolver.dart';
import '../logging/feature_logger.dart';

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
  sl.registerLazySingleton<FeatureLogger>(() => FeatureLogger(sl<AppLogger>()));
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
      featureLogger: sl<FeatureLogger>(),
    ),
  );
}

void _registerFeatureDependencies() {
  registerAuthDependencies(sl);
  sl.registerLazySingleton<WorkshopRemoteDataSource>(
    () => WorkshopRemoteDataSourceImpl(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<AppointmentBookingRemoteDataSource>(
    () => SupabaseAppointmentBookingRemoteDataSource(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<AppointmentBookingRepository>(
    () => AppointmentBookingRepositoryImpl(
      sl<AppointmentBookingRemoteDataSource>(),
    ),
  );
  sl.registerLazySingleton<WorkshopRepository>(
    () => WorkshopRepositoryImpl(
      remoteDataSource: sl<WorkshopRemoteDataSource>(),
      errorHandler: sl<GlobalErrorHandler>(),
      featureLogger: sl<FeatureLogger>(),
    ),
  );
  sl.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSourceImpl(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(
      remoteDataSource: sl<ProductRemoteDataSource>(),
      errorHandler: sl<GlobalErrorHandler>(),
      featureLogger: sl<FeatureLogger>(),
    ),
  );
  sl.registerLazySingleton<AppointmentRemoteDataSource>(
    () => AppointmentRemoteDataSourceImpl(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<AppointmentRepository>(
    () => AppointmentRepositoryImpl(
      remoteDataSource: sl<AppointmentRemoteDataSource>(),
      errorHandler: sl<GlobalErrorHandler>(),
      featureLogger: sl<FeatureLogger>(),
      currentUserIdProvider: () => sl<SupabaseClient>().auth.currentUser?.id,
    ),
  );
  sl.registerLazySingleton<GetSchedulableServicesByWorkshop>(
    () => GetSchedulableServicesByWorkshop(sl<ProductRepository>()),
  );
  sl.registerLazySingleton<GetAdditionalProductsByWorkshop>(
    () => GetAdditionalProductsByWorkshop(sl<ProductRepository>()),
  );
  sl.registerLazySingleton<GetCustomerVehicles>(
    () => GetCustomerVehicles(sl<AppointmentBookingRepository>()),
  );
  sl.registerLazySingleton<GetCustomerVehicleByPlate>(
    () => GetCustomerVehicleByPlate(sl<AppointmentBookingRepository>()),
  );
  sl.registerLazySingleton<IsAppointmentSlotAvailable>(
    () => IsAppointmentSlotAvailable(sl<AppointmentBookingRepository>()),
  );
  sl.registerLazySingleton<GetBookedAppointmentSlots>(
    () => GetBookedAppointmentSlots(sl<AppointmentBookingRepository>()),
  );
  sl.registerLazySingleton<BookServiceAppointment>(
    () => BookServiceAppointment(sl<AppointmentBookingRepository>()),
  );
  sl.registerLazySingleton<WorkshopDiscoveryQueryStore>(
    WorkshopDiscoveryQueryStore.new,
  );
  sl.registerLazySingleton<RecentSearchesStore>(
    () => SharedPreferencesRecentSearchesStore(sl<SharedPreferences>()),
  );
  sl.registerFactory<AppointmentCubit>(
    () => AppointmentCubit(
      workshopRepository: sl<WorkshopRepository>(),
      getSchedulableServices: sl<GetSchedulableServicesByWorkshop>(),
      getAdditionalProducts: sl<GetAdditionalProductsByWorkshop>(),
      getCustomerVehicles: sl<GetCustomerVehicles>(),
      getCustomerVehicleByPlate: sl<GetCustomerVehicleByPlate>(),
      isAppointmentSlotAvailable: sl<IsAppointmentSlotAvailable>(),
      getBookedAppointmentSlots: sl<GetBookedAppointmentSlots>(),
      bookServiceAppointment: sl<BookServiceAppointment>(),
    ),
  );
  sl.registerFactory<CreateAppointmentCubit>(
    () => CreateAppointmentCubit(sl<AppointmentRepository>()),
  );
  sl.registerFactory<MyAppointmentsCubit>(
    () => MyAppointmentsCubit(sl<AppointmentRepository>()),
  );
  sl.registerFactory<MapCubit>(
    () => MapCubit(
      sl<WorkshopRepository>(),
      sl<ProductRepository>(),
      sl<FeatureLogger>(),
      queryStore: sl<WorkshopDiscoveryQueryStore>(),
    ),
  );
}
