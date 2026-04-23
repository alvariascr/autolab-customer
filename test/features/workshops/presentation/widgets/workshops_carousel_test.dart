import 'package:autolab_customer/features/workshops/domain/entities/workshop.dart';
import 'package:autolab_customer/features/workshops/presentation/widgets/workshop_card.dart';
import 'package:autolab_customer/features/workshops/presentation/widgets/workshops_carousel.dart';
import 'package:autolab_customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkshopsCarousel', () {
    testWidgets('muestra mensaje vacio cuando no hay talleres', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              height: 320,
              child: const WorkshopsCarousel(
                workshops: [],
                emptyMessage: 'No hay talleres disponibles',
              ),
            ),
          ),
        ),
      );

      expect(find.text('No hay talleres disponibles'), findsOneWidget);
    });

    testWidgets('renderiza una card por cada taller recibido', (tester) async {
      const workshops = [
        Workshop(
          id: '1',
          name: 'Autolab Escazu',
          description: 'Servicio general',
          locationAddress: 'Escazu Centro',
          avatarUrl: '',
          coverUrl: '',
          latitude: 9.9330,
          longitude: -84.0800,
          deliveryRadiusKm: 8,
        ),
        Workshop(
          id: '2',
          name: 'Autolab Heredia',
          description: 'Frenos y suspension',
          locationAddress: 'Heredia Centro',
          avatarUrl: '',
          coverUrl: '',
          latitude: 10.0024,
          longitude: -84.1165,
          deliveryRadiusKm: 12,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              height: 320,
              child: const WorkshopsCarousel(
                workshops: workshops,
                emptyMessage: 'No hay talleres disponibles',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(WorkshopCard), findsWidgets);
      expect(find.text('Autolab Escazu'), findsWidgets);
      expect(find.text('Autolab Heredia'), findsWidgets);
    });
  });
}
