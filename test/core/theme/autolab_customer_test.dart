import 'package:autolab_customer/core/theme/autolab_customer.dart';
import 'package:autolab_customer/features/products/presentation/pages/workshop_search_products_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AutolabCustomer ThemeData', () {
    test('configura el tema claro con los tokens de marca', () {
      final theme = AutolabCustomer.lightTheme;

      expect(theme.brightness, Brightness.light);
      expect(
        theme.textTheme.bodyMedium?.fontFamily,
        AutolabCustomer.primaryFont,
      );
      expect(theme.colorScheme.primary, AutolabCustomer.primary);
      expect(
        theme.scaffoldBackgroundColor,
        AutolabCustomer.customerLightBackground,
      );
      expect(theme.colorScheme.surface, AutolabCustomer.customerLightSurface);
      expect(theme.colorScheme.onSurface, AutolabCustomer.customerLightText);
      expect(theme.colorScheme.outline, AutolabCustomer.customerLightDivider);
      expect(theme.textTheme.headlineMedium?.fontSize, 24);
    });

    test('configura superficies y texto legibles en modo oscuro', () {
      final theme = AutolabCustomer.darkTheme;

      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, AutolabCustomer.darkBackground);
      expect(theme.colorScheme.surface, AutolabCustomer.darkSurface);
      expect(theme.colorScheme.onSurface, AutolabCustomer.white);
      expect(theme.textTheme.bodyMedium?.color, AutolabCustomer.white);
    });

    test('expone colores funcionales mediante ThemeExtension', () {
      final colors = AutolabCustomer.darkTheme.extension<AutolabCustomColors>();

      expect(colors, isNotNull);
      expect(colors?.appointmentConfirmed, AutolabCustomer.success);
      expect(colors?.appointmentCompleted, AutolabCustomer.white);
      expect(colors?.info, AutolabCustomer.info);
    });

    testWidgets(
      'mantiene contraste del filtro disponible seleccionado en ambos temas',
      (tester) async {
        final selectedColors = <Color>[];

        for (final theme in [
          AutolabCustomer.lightTheme,
          AutolabCustomer.darkTheme,
        ]) {
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              home: Builder(
                builder: (context) {
                  selectedColors.add(
                    workshopSearchAvailabilityChipLabelStyle(
                      context,
                      isSelected: true,
                    ).color!,
                  );

                  return const SizedBox.shrink();
                },
              ),
            ),
          );
        }

        expect(selectedColors, [
          AutolabCustomer.successText,
          AutolabCustomer.successText,
        ]);
      },
    );
  });
}
