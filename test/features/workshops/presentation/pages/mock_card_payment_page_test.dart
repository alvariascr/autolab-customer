import 'package:autolab_customer/core/theme/autolab_customer.dart';
import 'package:autolab_customer/features/workshops/presentation/pages/mock_card_payment_page.dart';
import 'package:autolab_customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MockCardPaymentPage', () {
    testWidgets('usa la superficie clara cuando el tema es claro', (
      tester,
    ) async {
      await _pumpPaymentPage(tester, AutolabCustomer.lightTheme);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AutolabCustomer.customerLightSurface);
    });

    testWidgets('usa la superficie oscura cuando el tema es oscuro', (
      tester,
    ) async {
      await _pumpPaymentPage(tester, AutolabCustomer.darkTheme);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AutolabCustomer.customerDarkSurface);
    });
  });
}

Future<void> _pumpPaymentPage(WidgetTester tester, ThemeData theme) {
  return tester.pumpWidget(
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
        amountLabel: 'CRC 30.000',
        workshopName: 'Servicentro Tilaran',
        onClose: () {},
      ),
    ),
  );
}
