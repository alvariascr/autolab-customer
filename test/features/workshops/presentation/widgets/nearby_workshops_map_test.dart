import 'dart:async';

import 'package:autolab_customer/core/location/current_location.dart';
import 'package:autolab_customer/features/workshops/domain/entities/workshop.dart';
import 'package:autolab_customer/features/workshops/presentation/widgets/nearby_workshops_map.dart';
import 'package:autolab_customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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

    testWidgets('muestra boton interactivo para centrar ubicacion actual', (
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

      final locationButton = find.byKey(
        const ValueKey('map-current-location-button'),
      );

      expect(locationButton, findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
              find.descendant(
                of: locationButton,
                matching: find.byType(IconButton),
              ),
            )
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('ignora regiones visibles obsoletas del mapa', (tester) async {
      const workshops = [
        Workshop(
          id: 'oeste',
          name: 'Taller Oeste',
          description: '',
          locationAddress: 'Oeste',
          avatarUrl: '',
          coverUrl: '',
          latitude: 10,
          longitude: -85,
          deliveryRadiusKm: 8,
        ),
        Workshop(
          id: 'este',
          name: 'Taller Este',
          description: '',
          locationAddress: 'Este',
          avatarUrl: '',
          coverUrl: '',
          latitude: 10,
          longitude: -84,
          deliveryRadiusKm: 8,
        ),
      ];
      final firstRegion = Completer<LatLngBounds>();
      final secondRegion = Completer<LatLngBounds>();
      var requestCount = 0;

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
              height: 640,
              child: NearbyWorkshopsMap(
                workshops: workshops,
                currentLocation: const CurrentLocation(
                  latitude: 10,
                  longitude: -84.5,
                ),
                emptyMessage: 'No encontramos talleres cercanos.',
                visibleRegionProvider: () {
                  requestCount += 1;
                  return requestCount == 1
                      ? firstRegion.future
                      : secondRegion.future;
                },
              ),
            ),
          ),
        ),
      );

      final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      googleMap.onCameraIdle?.call();
      googleMap.onCameraIdle?.call();

      secondRegion.complete(
        LatLngBounds(
          southwest: const LatLng(9.5, -84.5),
          northeast: const LatLng(10.5, -83.5),
        ),
      );
      await tester.pump();

      expect(find.text('Taller Este'), findsWidgets);

      firstRegion.complete(
        LatLngBounds(
          southwest: const LatLng(9.5, -85.5),
          northeast: const LatLng(10.5, -84.5),
        ),
      );
      await tester.pump();

      expect(find.text('Taller Este'), findsWidgets);
      expect(find.text('Taller Oeste'), findsNothing);
    });

    testWidgets('abre el perfil del taller desde resultados de busqueda', (
      tester,
    ) async {
      const workshops = [
        Workshop(
          id: 'principal',
          name: 'Autolab Taller Principal',
          description: '',
          locationAddress: '300Metros sur del MAG',
          avatarUrl: '',
          coverUrl: '',
          latitude: 9.9285,
          longitude: -84.0901,
          deliveryRadiusKm: 9,
        ),
        Workshop(
          id: 'este',
          name: 'Autolab Taller Este',
          description: '',
          locationAddress: 'Avenida 2',
          avatarUrl: '',
          coverUrl: '',
          latitude: 9.9295,
          longitude: -84.0890,
          deliveryRadiusKm: 6,
        ),
      ];

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(
              body: SizedBox(
                height: 640,
                child: NearbyWorkshopsMap(
                  workshops: workshops,
                  currentLocation: CurrentLocation(
                    latitude: 9.9281,
                    longitude: -84.0907,
                  ),
                  emptyMessage: 'No encontramos talleres cercanos.',
                  query: 'autolab',
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/workshops/:id',
            builder: (context, state) =>
                Scaffold(body: Text('Perfil ${state.pathParameters['id']}')),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      );
      await tester.pump();

      expect(find.text('2 resultados'), findsOneWidget);

      await tester.tap(find.text('Autolab Taller Principal'));
      await tester.pumpAndSettle();

      expect(find.text('Perfil principal'), findsOneWidget);
    });
  });
}
