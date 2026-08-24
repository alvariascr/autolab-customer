import 'dart:async';

import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/core/di/app_injection.dart';
import 'package:autolab_customer/features/payments/domain/entities/laropay_purchase.dart';
import 'package:autolab_customer/features/payments/domain/repositories/laropay_purchase_repository.dart';
import 'package:autolab_customer/features/payments/domain/usecases/get_laropay_purchases.dart';
import 'package:autolab_customer/features/payments/domain/usecases/refresh_laropay_purchase_status.dart';
import 'package:autolab_customer/features/payments/presentation/pages/my_purchases_page.dart';
import 'package:autolab_customer/l10n/app_localizations.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockLaropayPurchaseRepository extends Mock
    implements LaropayPurchaseRepository {}

void main() {
  group('MyPurchasesPage estado cancelado', () {
    late _MockLaropayPurchaseRepository repository;

    setUp(() {
      repository = _MockLaropayPurchaseRepository();
      sl.registerFactory<GetLaropayPurchases>(
        () => GetLaropayPurchases(repository),
      );
      sl.registerFactory<RefreshLaropayPurchaseStatus>(
        () => RefreshLaropayPurchaseStatus(repository),
      );
    });

    tearDown(() async {
      await sl.unregister<GetLaropayPurchases>();
      await sl.unregister<RefreshLaropayPurchaseStatus>();
    });

    testWidgets(
      'muestra Cancelado con mensaje propio, distinto de Rechazado, y sin acciones de reintento',
      (tester) async {
        when(
          () => repository.getRecentPurchases(),
        ).thenAnswer((_) async => Right([_purchase(status: 'cancelled')]));

        await tester.pumpWidget(_TestApp(router: _buildRouter()));
        await tester.pumpAndSettle();

        expect(find.text('Cancelado'), findsOneWidget);
        expect(find.text('No procesado'), findsNothing);
        expect(find.text('Reintentar pago'), findsNothing);
        expect(find.text('Actualizar estado'), findsNothing);

        // The status message lives behind "Ver detalle" now.
        expect(
          find.text(
            'Los productos y el cupo quedaron liberados. Puedes agendar o comprar de nuevo cuando quieras.',
          ),
          findsNothing,
        );
        await tester.tap(find.text('Ver detalle'));
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Los productos y el cupo quedaron liberados. Puedes agendar o comprar de nuevo cuando quieras.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'el retorno de un pago cancelado muestra un mensaje distinto al de rechazado',
      (tester) async {
        const paymentLinkId = '123e4567-e89b-12d3-a456-426614174000';
        when(
          () => repository.getRecentPurchases(),
        ).thenAnswer((_) async => const Right([]));
        when(
          () => repository.refreshPurchaseStatus(paymentLinkId),
        ).thenAnswer((_) async => Right(_purchase(status: 'cancelled')));

        await tester.pumpWidget(
          _TestApp(router: _buildRouter(paymentLinkId: paymentLinkId)),
        );
        // The outcome is shown in a modal dialog that never auto-dismisses,
        // so pump explicitly instead of pumpAndSettle (which would hang on
        // the still-open dialog / loading spinner).
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Orden cancelada'), findsOneWidget);
        expect(
          find.text(
            'La pasarela de pago no pudo procesar el pago. Puedes revisar el estado o intentar nuevamente desde Mis órdenes.',
          ),
          findsNothing,
        );

        await tester.tap(find.text('Cerrar'));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'mientras se confirma el resultado del pago, no muestra acciones de una orden ya resuelta',
      (tester) async {
        const paymentLinkId = '123e4567-e89b-12d3-a456-426614174000';
        final refreshCompleter = Completer<Either<Failure, LaropayPurchase>>();
        // Mirrors the real backend: the order still reads as pending until
        // the return-payment check finishes persisting the cancellation.
        var hasBeenCancelled = false;

        when(() => repository.getRecentPurchases()).thenAnswer(
          (_) async => Right([
            _purchase(status: hasBeenCancelled ? 'cancelled' : 'pending'),
          ]),
        );
        when(
          () => repository.refreshPurchaseStatus(paymentLinkId),
        ).thenAnswer((_) => refreshCompleter.future);

        await tester.pumpWidget(
          _TestApp(router: _buildRouter(paymentLinkId: paymentLinkId)),
        );
        await tester.pump();
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsWidgets);
        expect(find.text('Reintentar pago'), findsNothing);
        expect(find.text('Actualizar estado'), findsNothing);

        hasBeenCancelled = true;
        refreshCompleter.complete(Right(_purchase(status: 'cancelled')));
        // The outcome dialog never auto-dismisses -- pump explicitly, then
        // close it, before using pumpAndSettle again.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Reintentar pago'), findsNothing);
        expect(find.text('Actualizar estado'), findsNothing);

        await tester.tap(find.text('Cerrar'));
        await tester.pumpAndSettle();

        expect(find.text('Reintentar pago'), findsNothing);
        expect(find.text('Actualizar estado'), findsNothing);
      },
    );
  });
}

LaropayPurchase _purchase({required String status}) {
  return LaropayPurchase(
    id: 'purchase-1',
    amount: 25000,
    currencyCode: 'CRC',
    detail: 'Compra de prueba',
    linkId: 'LINK-1',
    status: status,
    responseCode: '17',
    responseDescription: 'CANCELACION DEL CLIENTE',
    rejectReason: 'CANCELACION DEL CLIENTE',
    createdAt: DateTime(2026, 8, 14),
    expiresAt: null,
    hasPaymentLink: true,
    linkUrl: Uri.parse('https://laropay.example.com/pay/abc'),
  );
}

GoRouter _buildRouter({String? paymentLinkId}) {
  return GoRouter(
    initialLocation: paymentLinkId == null
        ? '/purchases'
        : '/purchases?paymentLinkId=$paymentLinkId',
    routes: [
      GoRoute(
        path: '/purchases',
        builder: (context, state) => MyPurchasesPage(
          showBottomNavigation: false,
          paymentLinkId: state.uri.queryParameters['paymentLinkId'],
        ),
      ),
    ],
  );
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
