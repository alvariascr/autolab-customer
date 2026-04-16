import 'package:autolab_customer/core/location/current_location.dart';
import 'package:autolab_customer/features/workshops/domain/entities/workshop.dart';
import 'package:autolab_customer/features/workshops/presentation/widgets/workshop_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkshopCard', () {
    testWidgets('muestra nombre y descripcion del taller', (tester) async {
      const workshop = Workshop(
        id: '1',
        name: 'Autolab Escazu',
        description: 'Cambio de aceite y frenos.',
        locationAddress: 'Escazu Centro',
        avatarUrl: '',
        coverUrl: '',
        latitude: 9.9330,
        longitude: -84.0800,
        deliveryRadiusKm: 8,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 320,
              child: WorkshopCard(
                workshop: workshop,
                referenceLocation: CurrentLocation(
                  latitude: 9.9281,
                  longitude: -84.0907,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Autolab Escazu'), findsOneWidget);
      expect(find.text('Cambio de aceite y frenos.'), findsOneWidget);
      expect(find.text('Escazu Centro'), findsOneWidget);
      expect(find.textContaining('Cobertura'), findsOneWidget);
      expect(find.textContaining('A '), findsOneWidget);
      expect(find.byIcon(Icons.store), findsOneWidget);
      expect(find.byIcon(Icons.image), findsOneWidget);
    });

    testWidgets('muestra fallback cuando no hay descripcion', (tester) async {
      const workshop = Workshop(
        id: '1',
        name: 'Autolab Heredia',
        description: '',
        locationAddress: '',
        avatarUrl: '',
        coverUrl: '',
        latitude: 10.0024,
        longitude: -84.1165,
        deliveryRadiusKm: 12,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 320,
              child: WorkshopCard(workshop: workshop),
            ),
          ),
        ),
      );

      expect(find.text('Sin descripción disponible'), findsOneWidget);
    });
  });
}
