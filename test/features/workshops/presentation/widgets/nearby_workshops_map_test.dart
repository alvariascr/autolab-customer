import 'package:autolab_customer/core/location/current_location.dart';
import 'package:autolab_customer/features/workshops/domain/entities/workshop.dart';
import 'package:autolab_customer/features/workshops/presentation/widgets/nearby_workshops_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NearbyWorkshopsMap', () {
    testWidgets('mantiene el mapa visible cuando no hay talleres cercanos', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 320,
              child: NearbyWorkshopsMap(
                workshops: [],
                currentLocation: CurrentLocation(
                  latitude: 9.9281,
                  longitude: -84.0907,
                ),
                emptyMessage: 'No encontramos talleres cercanos.',
              ),
            ),
          ),
        ),
      );

      expect(find.text('No encontramos talleres cercanos.'), findsOneWidget);
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(
        find.byKey(const ValueKey('current-location-marker')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('nearby-workshops-empty-message')),
        findsOneWidget,
      );
    });

    testWidgets('renderiza marcadores del usuario y de cada taller', (
      tester,
    ) async {
      const workshops = [
        Workshop(
          id: '1',
          name: 'Autolab Escazu',
          description: '',
          avatarUrl: '',
          coverUrl: '',
          latitude: 9.9330,
          longitude: -84.0800,
        ),
        Workshop(
          id: '2',
          name: 'Autolab Heredia',
          description: '',
          avatarUrl: '',
          coverUrl: '',
          latitude: 10.0024,
          longitude: -84.1165,
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 320,
              child: NearbyWorkshopsMap(
                workshops: workshops,
                currentLocation: CurrentLocation(
                  latitude: 9.9281,
                  longitude: -84.0907,
                ),
                emptyMessage: 'No encontramos talleres cercanos.',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('current-location-marker')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('workshop-marker-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('workshop-marker-2')), findsOneWidget);
    });

    testWidgets('muestra controles de zoom sobre el mapa', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 320,
              child: NearbyWorkshopsMap(
                workshops: [],
                currentLocation: CurrentLocation(
                  latitude: 9.9281,
                  longitude: -84.0907,
                ),
                emptyMessage: 'No encontramos talleres cercanos.',
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('map-zoom-in-button')), findsOneWidget);
      expect(find.byKey(const ValueKey('map-zoom-out-button')), findsOneWidget);
    });
  });
}
