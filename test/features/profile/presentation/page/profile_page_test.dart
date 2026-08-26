import 'package:autolab_customer/core/di/app_injection.dart';
import 'package:autolab_customer/core/theme/app_theme_mode_cubit.dart';
import 'package:autolab_customer/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:autolab_customer/features/appointments/presentation/cubit/my_appointments_cubit.dart';
import 'package:autolab_customer/features/appointments/presentation/pages/my_appointments_page.dart';
import 'package:autolab_customer/features/auth/application/auth_session_cubit.dart';
import 'package:autolab_customer/features/auth/application/auth_session_state.dart';
import 'package:autolab_customer/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:autolab_customer/features/notifications/presentation/cubit/notifications_state.dart';
import 'package:autolab_customer/features/notifications/presentation/pages/notifications_page.dart';
import 'package:autolab_customer/features/profile/application/garage_vehicle_image_service.dart';
import 'package:autolab_customer/features/profile/domain/repositories/garage_vehicle_repository.dart';
import 'package:autolab_customer/features/profile/domain/usecases/get_default_garage_vehicle.dart';
import 'package:autolab_customer/features/profile/domain/usecases/get_garage_vehicles.dart';
import 'package:autolab_customer/features/profile/presentation/page/profile_page.dart';
import 'package:autolab_customer/features/profile/presentation/page/vehicles_page.dart';
import 'package:autolab_customer/l10n/app_localizations.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthSessionCubit extends MockCubit<AuthSessionState>
    implements AuthSessionCubit {}

class _MockAppointmentRepository extends Mock
    implements AppointmentRepository {}

class _MockGarageVehicleRepository extends Mock
    implements GarageVehicleRepository {}

class _MockGarageVehicleImageService extends Mock
    implements GarageVehicleImageService {}

class _MockNotificationsCubit extends MockCubit<NotificationsState>
    implements NotificationsCubit {}

void main() {
  group('ProfilePage navigation', () {
    late _MockAuthSessionCubit authSessionCubit;
    late _MockAppointmentRepository appointmentRepository;
    late _MockGarageVehicleRepository vehicleRepository;
    late _MockGarageVehicleImageService vehicleImageService;

    setUp(() {
      authSessionCubit = _MockAuthSessionCubit();
      appointmentRepository = _MockAppointmentRepository();
      vehicleRepository = _MockGarageVehicleRepository();
      vehicleImageService = _MockGarageVehicleImageService();

      when(
        () => authSessionCubit.state,
      ).thenReturn(const AuthSessionState.initial());
      when(() => authSessionCubit.logout()).thenAnswer((_) async {});
      when(
        () => appointmentRepository.getCustomerAppointments(),
      ).thenAnswer((_) async => const Right([]));
      when(() => vehicleRepository.getVehicles()).thenAnswer((_) async => []);
      when(
        () => vehicleRepository.getDefaultVehicle(),
      ).thenAnswer((_) async => null);
      when(
        () => vehicleImageService.loadLocalImages(),
      ).thenAnswer((_) async => {});
      when(
        () => vehicleImageService.uploadLegacyImages(any()),
      ).thenAnswer((_) async => false);

      sl.registerFactory(() => MyAppointmentsCubit(appointmentRepository));
      sl.registerSingleton<GetGarageVehicles>(
        GetGarageVehicles(vehicleRepository),
      );
      sl.registerSingleton<GetDefaultGarageVehicle>(
        GetDefaultGarageVehicle(vehicleRepository),
      );
      sl.registerSingleton<GarageVehicleRepository>(vehicleRepository);
      sl.registerSingleton<GarageVehicleImageService>(vehicleImageService);
    });

    tearDown(() async {
      await sl.unregister<MyAppointmentsCubit>();
      await sl.unregister<GetGarageVehicles>();
      await sl.unregister<GetDefaultGarageVehicle>();
      await sl.unregister<GarageVehicleRepository>();
      await sl.unregister<GarageVehicleImageService>();
    });

    testWidgets('abre mis citas manteniendo perfil en el stack', (
      tester,
    ) async {
      final router = _buildRouter();

      await tester.pumpWidget(
        _TestApp(router: router, authSessionCubit: authSessionCubit),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.calendar_month_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(MyAppointmentsPage), findsOneWidget);
      expect(router.canPop(), true);

      await tester.tap(find.byIcon(Icons.arrow_back_rounded).first);
      await tester.pumpAndSettle();

      expect(find.byType(ProfilePage), findsOneWidget);
    });

    testWidgets('abre vehiculos manteniendo perfil en el stack', (
      tester,
    ) async {
      final router = _buildRouter();

      await tester.pumpWidget(
        _TestApp(router: router, authSessionCubit: authSessionCubit),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.directions_car_filled_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(VehiclesPage), findsOneWidget);
      expect(router.canPop(), true);

      await tester.tap(find.byIcon(Icons.arrow_back_rounded).first);
      await tester.pumpAndSettle();

      expect(find.byType(ProfilePage), findsOneWidget);
    });

    testWidgets('abre notificaciones manteniendo perfil en el stack', (
      tester,
    ) async {
      final router = _buildRouter();

      await tester.pumpWidget(
        _TestApp(router: router, authSessionCubit: authSessionCubit),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Notificaciones').first);
      await tester.pumpAndSettle();

      expect(find.byType(NotificationsPage), findsOneWidget);
      expect(find.text('No tienes notificaciones'), findsOneWidget);
      expect(router.canPop(), true);

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(ProfilePage), findsOneWidget);
    });
  });
}

GoRouter _buildRouter() {
  final notificationsCubit = _MockNotificationsCubit();
  when(
    () => notificationsCubit.state,
  ).thenReturn(NotificationsState(status: NotificationsStatus.success));
  when(() => notificationsCubit.load()).thenAnswer((_) async {});
  return GoRouter(
    initialLocation: '/profile',
    routes: [
      GoRoute(
        path: '/profile',
        builder: (_, _) => BlocProvider<NotificationsCubit>.value(
          value: notificationsCubit,
          child: const ProfilePage(),
        ),
      ),
      GoRoute(
        path: '/appointments',
        builder: (_, _) => BlocProvider<NotificationsCubit>.value(
          value: notificationsCubit,
          child: const MyAppointmentsPage(),
        ),
      ),
      GoRoute(path: '/vehicles', builder: (_, _) => const VehiclesPage()),
      GoRoute(
        path: NotificationsPage.routePath,
        builder: (_, _) => BlocProvider<NotificationsCubit>.value(
          value: notificationsCubit,
          child: const NotificationsPage(),
        ),
      ),
    ],
  );
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.router, required this.authSessionCubit});

  final GoRouter router;
  final AuthSessionCubit authSessionCubit;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthSessionCubit>.value(value: authSessionCubit),
        BlocProvider(create: (_) => AppThemeModeCubit()),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }
}
