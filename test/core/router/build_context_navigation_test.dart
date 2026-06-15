import 'package:autolab_customer/core/router/build_context_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('hace pop cuando existe una ruta anterior', (tester) async {
    final router = _buildRouter();

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.push('/details');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Regresar'));
    await tester.pumpAndSettle();

    expect(find.text('Inicio'), findsOneWidget);
  });

  testWidgets('navega al fallback cuando no existe historial', (tester) async {
    final router = _buildRouter(initialLocation: '/details');

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Regresar'));
    await tester.pumpAndSettle();

    expect(find.text('Fallback'), findsOneWidget);
  });
}

GoRouter _buildRouter({String initialLocation = '/'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('Inicio')),
      ),
      GoRoute(
        path: '/details',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => context.popOrGo('/fallback'),
            child: const Text('Regresar'),
          ),
        ),
      ),
      GoRoute(
        path: '/fallback',
        builder: (_, _) => const Scaffold(body: Text('Fallback')),
      ),
    ],
  );
}
