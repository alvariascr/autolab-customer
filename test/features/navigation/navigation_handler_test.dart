import 'package:autolab_customer/features/navigation/navigation_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  Future<GoRouter> pumpRouter({
    required WidgetTester tester,
    required int navigationIndex,
  }) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Material(
            child: TextButton(
              onPressed: () =>
                  NavigationHandler.handle(context, navigationIndex),
              child: const Text('Navigate'),
            ),
          ),
        ),
        GoRoute(
          path: '/home-customer',
          builder: (context, state) => Text(state.uri.toString()),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('Navigate'));
    await tester.pumpAndSettle();

    return router;
  }

  testWidgets('abre el mapa dentro del shell del cliente', (tester) async {
    final router = await pumpRouter(tester: tester, navigationIndex: 1);

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/home-customer?tab=map',
    );
  });

  testWidgets('abre la busqueda dentro del shell del cliente', (tester) async {
    final router = await pumpRouter(tester: tester, navigationIndex: 2);

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/home-customer?tab=search',
    );
  });

  testWidgets('abre el carrito dentro del shell del cliente', (tester) async {
    final router = await pumpRouter(tester: tester, navigationIndex: 3);

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/home-customer?tab=cart',
    );
  });

  testWidgets('abre mi garaje dentro del shell del cliente', (tester) async {
    final router = await pumpRouter(tester: tester, navigationIndex: 4);

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/home-customer?tab=profile',
    );
  });
}
