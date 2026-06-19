import 'package:autolab_customer/core/location/current_location.dart';
import 'package:autolab_customer/core/location/location_state.dart';
import 'package:autolab_customer/features/home/widgets/workshops_section.dart';
import 'package:autolab_customer/features/workshops/domain/entities/workshop.dart';
import 'package:autolab_customer/features/workshops/domain/services/workshop_proximity_filter.dart';
import 'package:autolab_customer/features/workshops/presentation/workshop_empty_state_resolver.dart';
import 'package:autolab_customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkshopsSection', () {
    testWidgets('muestra los talleres cercanos sin exponer campo de busqueda', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.byKey(const ValueKey('workshop-search-field')), findsNothing);
      expect(find.text('Frenos Heredia'), findsWidgets);
      expect(find.text('Autolab Escazu'), findsWidgets);
    });
  });
}

Widget _buildTestApp() {
  const locationState = LocationState(
    status: LocationFlowStatus.success,
    location: CurrentLocation(latitude: 9.9330, longitude: -84.0800),
  );

  const workshops = [
    Workshop(
      id: '1',
      name: 'Autolab Escazu',
      description: 'Mantenimiento general',
      locationAddress: 'Escazu Centro',
      avatarUrl: '',
      coverUrl: '',
      latitude: 9.9330,
      longitude: -84.0800,
      deliveryRadiusKm: 8,
    ),
    Workshop(
      id: '2',
      name: 'Frenos Heredia',
      description: 'Especialistas en frenos',
      locationAddress: 'Heredia Centro',
      avatarUrl: '',
      coverUrl: '',
      latitude: 9.9340,
      longitude: -84.0810,
      deliveryRadiusKm: 12,
    ),
  ];

  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(
        child: WorkshopsSection(
          workshops: workshops,
          locationState: locationState,
          proximityFilter: const WorkshopProximityFilter(),
          emptyStateResolver: const WorkshopEmptyStateResolver(),
          isLoading: false,
          workshopFailure: null,
          onViewAllTap: () {},
        ),
      ),
    ),
  );
}
