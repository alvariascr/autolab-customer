import 'package:autolab_customer/core/theme/autolab_customer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('el filtro disponible seleccionado mantiene contraste', (
    tester,
  ) async {
    const labelKey = Key('available-filter-label');

    for (final theme in [
      AutolabCustomer.lightTheme,
      AutolabCustomer.darkTheme,
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return FilterChip(
                  label: const Text('Disponibles', key: labelKey),
                  selected: true,
                  onSelected: (_) {},
                  backgroundColor: AutolabCustomer.customerSurfaceColor(
                    context,
                  ),
                  selectedColor: AutolabCustomer.successSoftBackground,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  labelStyle: AutolabCustomer.body.copyWith(
                    color: AutolabCustomer.successText,
                    fontWeight: FontWeight.w800,
                  ),
                );
              },
            ),
          ),
        ),
      );

      final defaultTextStyle = tester.widget<DefaultTextStyle>(
        find
            .ancestor(
              of: find.byKey(labelKey),
              matching: find.byType(DefaultTextStyle),
            )
            .first,
      );
      expect(defaultTextStyle.style.color, AutolabCustomer.successText);
    }
  });
}
