import 'package:autolab_customer/features/notifications/domain/entities/customer_notification.dart';
import 'package:autolab_customer/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:autolab_customer/features/notifications/presentation/cubit/notifications_state.dart';
import 'package:autolab_customer/features/notifications/presentation/widgets/customer_notification_bell.dart';
import 'package:autolab_customer/l10n/app_localizations.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockNotificationsCubit extends MockCubit<NotificationsState>
    implements NotificationsCubit {}

void main() {
  testWidgets('muestra un punto cuando existe una notificación sin leer', (
    tester,
  ) async {
    final cubit = _MockNotificationsCubit();
    when(() => cubit.state).thenReturn(
      NotificationsState(
        status: NotificationsStatus.success,
        notifications: [
          CustomerNotification(
            id: 'notification-1',
            title: 'Cita confirmada',
            body: 'Tu cita fue confirmada.',
            type: 'appointment',
            isRead: false,
            createdAt: DateTime(2026, 8, 20),
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      BlocProvider<NotificationsCubit>.value(
        value: cubit,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: CustomerNotificationBell(onTap: () {})),
        ),
      ),
    );

    expect(
      find.byKey(const Key('notification-unread-indicator')),
      findsOneWidget,
    );
  });
}
