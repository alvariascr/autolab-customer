import 'package:autolab_customer/features/auth/application/auth_session_cubit.dart';
import 'package:autolab_customer/features/auth/application/auth_session_state.dart';
import 'package:autolab_customer/features/profile/presentation/page/profile_page.dart';
import 'package:autolab_customer/l10n/app_localizations.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthSessionCubit extends MockCubit<AuthSessionState>
    implements AuthSessionCubit {}

void main() {
  group('ProfilePage navigation', () {
    late _MockAuthSessionCubit authSessionCubit;

    setUp(() {
      authSessionCubit = _MockAuthSessionCubit();
      when(
        () => authSessionCubit.state,
      ).thenReturn(const AuthSessionState.initial());
      when(() => authSessionCubit.logout()).thenAnswer((_) async {});
    });

    testWidgets('abre mis citas manteniendo perfil en el stack', (
      tester,
    ) async {
      final router = _buildRouter('/appointments');

      await tester.pumpWidget(
        _TestApp(router: router, authSessionCubit: authSessionCubit),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mis citas'));
      await tester.pumpAndSettle();

      expect(find.text('appointments page'), findsOneWidget);
      expect(router.canPop(), true);

      router.pop();
      await tester.pumpAndSettle();

      expect(find.byType(ProfilePage), findsOneWidget);
    });

    testWidgets('abre vehiculos manteniendo perfil en el stack', (
      tester,
    ) async {
      final router = _buildRouter('/vehicles');

      await tester.pumpWidget(
        _TestApp(router: router, authSessionCubit: authSessionCubit),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mis vehículos'));
      await tester.pumpAndSettle();

      expect(find.text('vehicles page'), findsOneWidget);
      expect(router.canPop(), true);

      router.pop();
      await tester.pumpAndSettle();

      expect(find.byType(ProfilePage), findsOneWidget);
    });
  });
}

GoRouter _buildRouter(String pushedPath) {
  return GoRouter(
    initialLocation: '/profile',
    routes: [
      GoRoute(path: '/profile', builder: (_, _) => const ProfilePage()),
      GoRoute(
        path: pushedPath,
        builder: (_, _) =>
            Scaffold(body: Text('${pushedPath.substring(1)} page')),
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
    return BlocProvider<AuthSessionCubit>.value(
      value: authSessionCubit,
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
