import 'package:autolab_customer/features/workshops/domain/entities/workshop.dart';
import 'package:autolab_customer/features/workshops/presentation/widgets/workshop_card.dart';
import 'package:autolab_customer/features/workshops/presentation/widgets/workshops_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkshopsCarousel', () {
    testWidgets('muestra mensaje vacio cuando no hay talleres', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 320,
              child: WorkshopsCarousel(workshops: []),
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
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 320,
              child: WorkshopsCarousel(workshops: workshops),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(WorkshopCard), findsNWidgets(2));
      expect(find.text('Autolab Escazu'), findsOneWidget);
      expect(find.text('Autolab Heredia'), findsOneWidget);
    });
  });
}
