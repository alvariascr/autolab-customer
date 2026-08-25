import 'package:autolab_customer/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:autolab_customer/features/notifications/presentation/cubit/notifications_state.dart';
import 'package:autolab_customer/features/notifications/presentation/pages/notifications_page.dart';
import 'package:autolab_customer/l10n/app_localizations.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockNotificationsCubit extends MockCubit<NotificationsState>
    implements NotificationsCubit {}

void main() {
  testWidgets('muestra el estado vacío del centro de notificaciones', (
    tester,
  ) async {
    final cubit = _MockNotificationsCubit();
    when(
      () => cubit.state,
    ).thenReturn(NotificationsState(status: NotificationsStatus.success));
    when(() => cubit.load()).thenAnswer((_) async {});
    final router = GoRouter(
      initialLocation: '/origin',
      routes: [
        GoRoute(
          path: '/origin',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () => context.push(NotificationsPage.routePath),
              child: const Text('Abrir'),
            ),
          ),
        ),
        GoRoute(
          path: NotificationsPage.routePath,
          builder: (context, state) => BlocProvider<NotificationsCubit>.value(
            value: cubit,
            child: const NotificationsPage(),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
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

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Notificaciones'), findsOneWidget);
    expect(find.text('No tienes notificaciones'), findsOneWidget);
    expect(
      find.text(
        'Te avisaremos cuando haya novedades sobre tus servicios y vehículos.',
      ),
      findsOneWidget,
    );
  });
}
