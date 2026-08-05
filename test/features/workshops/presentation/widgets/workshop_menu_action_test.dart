import 'package:autolab_customer/core/theme/autolab_customer.dart';
import 'package:autolab_customer/features/workshops/presentation/widgets/workshop_menu_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('usa color deshabilitado cuando la accion no esta disponible', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AutolabCustomer.lightTheme,
        home: const Scaffold(
          body: WorkshopMenuAction(
            icon: Icons.call_outlined,
            title: 'Llamar',
            enabled: false,
          ),
        ),
      ),
    );

    final context = tester.element(find.byType(WorkshopMenuAction));
    final disabledColor = AutolabCustomer.customerDisabledTextColor(context);

    final icon = tester.widget<Icon>(find.byIcon(Icons.call_outlined));
    final title = tester.widget<Text>(find.text('Llamar'));

    expect(icon.color, disabledColor);
    expect(title.style?.color, disabledColor);
  });
}
