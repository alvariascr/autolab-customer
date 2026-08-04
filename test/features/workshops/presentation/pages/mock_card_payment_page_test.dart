import 'package:autolab_customer/core/theme/autolab_customer.dart';
import 'package:autolab_customer/features/workshops/presentation/pages/mock_card_payment_page.dart';
import 'package:autolab_customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MockCardPaymentPage', () {
    testWidgets('respeta superficies de modo claro y oscuro', (tester) async {
      for (final theme in [
        AutolabCustomer.lightTheme,
        AutolabCustomer.darkTheme,
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());

        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey(theme.brightness),
            theme: theme,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: MockCardPaymentPage(
              appointmentId: 'appointment-1',
              amountLabel: '¢30.000',
              workshopName: 'Servicentro Tilarán',
              onClose: () {},
            ),
          ),
        );

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(
          scaffold.backgroundColor,
          theme.brightness == Brightness.dark
              ? AutolabCustomer.customerDarkSurface
              : AutolabCustomer.customerLightSurface,
        );
      }
    });
  });
}
