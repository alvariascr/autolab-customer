import 'package:autolab_customer/core/location/current_location.dart';
import 'package:autolab_customer/features/home/widgets/search_bar_overlay.dart';
import 'package:autolab_customer/features/workshops/domain/entities/workshop.dart';
import 'package:autolab_customer/features/workshops/presentation/widgets/workshop_card.dart';
import 'package:autolab_customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SearchBarOverlay', () {
    testWidgets('no muestra talleres antes de escribir una busqueda', (
      tester,
    ) async {
      final controller = TextEditingController();

      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _buildTestApp(controller: controller, showSearchBar: true),
      );
      await tester.pump();

      expect(
        find.text(
          'Ingresa el nombre, descripción o ubicación de un taller para encontrarlo más rápido.',
        ),
        findsOneWidget,
      );
      expect(find.byType(WorkshopCard), findsNothing);
      expect(find.text('Búsquedas sugeridas'), findsNothing);
      expect(
        find.byKey(const ValueKey('suggested-search-Frenos')),
        findsNothing,
      );
    });

    testWidgets('filtra talleres dentro de la vista superpuesta', (
      tester,
    ) async {
      final controller = TextEditingController();

      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _buildTestApp(controller: controller, showSearchBar: true),
      );

      await tester.enterText(
        find.byKey(const ValueKey('workshop-search-overlay-field')),
        'frenos',
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Frenos Heredia'), findsWidgets);
      expect(find.text('Autolab Escazu'), findsNothing);
    });

    testWidgets('muestra busquedas recientes como chips', (tester) async {
      final controller = TextEditingController();

      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _buildTestApp(controller: controller, showSearchBar: true),
      );

      await tester.enterText(
        find.byKey(const ValueKey('workshop-search-overlay-field')),
        'frenos',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(
        find.byKey(const ValueKey('workshop-search-clear-button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Búsquedas recientes'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('recent-search-frenos')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('recent-search-frenos')));
      await tester.pump(const Duration(milliseconds: 300));

      expect(controller.text, 'frenos');
      expect(find.text('Frenos Heredia'), findsWidgets);
    });

    testWidgets('guarda una busqueda reciente al limpiar el campo', (
      tester,
    ) async {
      final controller = TextEditingController();

      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _buildTestApp(controller: controller, showSearchBar: true),
      );

      await tester.enterText(
        find.byKey(const ValueKey('workshop-search-overlay-field')),
        'heredia',
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(
        find.byKey(const ValueKey('workshop-search-clear-button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Búsquedas recientes'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('recent-search-heredia')),
        findsOneWidget,
      );
    });

    testWidgets('muestra mensaje claro cuando no hay coincidencias', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'llantas');

      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _buildTestApp(controller: controller, showSearchBar: true),
      );
      await tester.pump();

      expect(
        find.text('No encontramos talleres que coincidan con tu búsqueda.'),
        findsOneWidget,
      );
    });

    testWidgets('notifica cierre desde el boton de regreso', (tester) async {
      final controller = TextEditingController(text: 'frenos');
      var didClose = false;

      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _buildTestApp(
          controller: controller,
          showSearchBar: true,
          onClose: () => didClose = true,
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('workshop-search-close-button')),
      );
      await tester.pump();

      expect(didClose, isTrue);
      expect(controller.text, isEmpty);
    });
  });
}

Widget _buildTestApp({
  required TextEditingController controller,
  required bool showSearchBar,
  VoidCallback? onClose,
}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Stack(
        children: [
          SearchBarOverlay(
            showSearchBar: showSearchBar,
            controller: controller,
            workshops: _workshops,
            currentLocation: const CurrentLocation(
              latitude: 9.9330,
              longitude: -84.0800,
            ),
            isLoading: false,
            workshopFailure: null,
            onClose: onClose ?? () {},
          ),
        ],
      ),
    ),
  );
}

const _workshops = [
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
    serviceCategories: ['Mantenimiento'],
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
    serviceCategories: ['Frenos'],
  ),
];
