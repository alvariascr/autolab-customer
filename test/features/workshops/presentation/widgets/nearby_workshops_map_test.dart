import 'package:autolab_customer/core/location/current_location.dart';
import 'package:autolab_customer/features/workshops/domain/entities/workshop.dart';
import 'package:autolab_customer/features/workshops/presentation/widgets/nearby_workshops_map.dart';
import 'package:autolab_customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  group('NearbyWorkshopsMap', () {
    testWidgets('mantiene el mapa visible cuando no hay talleres cercanos', (
      tester,
    ) async {
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
              child: const NearbyWorkshopsMap(
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
      final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));

      expect(googleMap.markers, hasLength(1));
      expect(googleMap.markers.first.markerId.value, 'current-location');
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
          description: '',
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
              child: const NearbyWorkshopsMap(
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

      final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      final markerIds = googleMap.markers
          .map((marker) => marker.markerId.value)
          .toSet();

      expect(
        markerIds,
        containsAll(['current-location', 'workshop-1', 'workshop-2']),
      );
    });

    testWidgets('muestra controles de zoom sobre el mapa', (tester) async {
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
              child: const NearbyWorkshopsMap(
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
