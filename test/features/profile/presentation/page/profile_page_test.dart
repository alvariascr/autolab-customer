import 'package:autolab_customer/core/di/app_injection.dart';
import 'package:autolab_customer/core/theme/app_theme_mode_cubit.dart';
import 'package:autolab_customer/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:autolab_customer/features/appointments/presentation/cubit/my_appointments_cubit.dart';
import 'package:autolab_customer/features/appointments/presentation/pages/my_appointments_page.dart';
import 'package:autolab_customer/features/auth/application/auth_session_cubit.dart';
import 'package:autolab_customer/features/auth/application/auth_session_state.dart';
import 'package:autolab_customer/features/profile/data/garage_vehicle_remote_data_source.dart';
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

class _MockGarageVehicleRemoteDataSource extends Mock
    implements GarageVehicleRemoteDataSource {}

void main() {
  group('ProfilePage navigation', () {
    late _MockAuthSessionCubit authSessionCubit;
    late _MockAppointmentRepository appointmentRepository;
    late _MockGarageVehicleRemoteDataSource vehicleDataSource;

    setUp(() {
      authSessionCubit = _MockAuthSessionCubit();
      appointmentRepository = _MockAppointmentRepository();
      vehicleDataSource = _MockGarageVehicleRemoteDataSource();

      when(
        () => authSessionCubit.state,
      ).thenReturn(const AuthSessionState.initial());
      when(() => authSessionCubit.logout()).thenAnswer((_) async {});
      when(
        () => appointmentRepository.getCustomerAppointments(),
      ).thenAnswer((_) async => const Right([]));
      when(() => vehicleDataSource.getVehicles()).thenAnswer((_) async => []);

      sl.registerFactory(() => MyAppointmentsCubit(appointmentRepository));
      sl.registerSingleton<GarageVehicleRemoteDataSource>(vehicleDataSource);
    });

    tearDown(() async {
      await sl.unregister<MyAppointmentsCubit>();
      await sl.unregister<GarageVehicleRemoteDataSource>();
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
  });
}

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/profile',
    routes: [
      GoRoute(path: '/profile', builder: (_, _) => const ProfilePage()),
      GoRoute(
        path: '/appointments',
        builder: (_, _) => const MyAppointmentsPage(),
      ),
      GoRoute(path: '/vehicles', builder: (_, _) => const VehiclesPage()),
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
