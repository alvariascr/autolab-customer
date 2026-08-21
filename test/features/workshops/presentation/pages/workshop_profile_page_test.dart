import 'package:autolab_customer/core/di/app_injection.dart';
import 'package:autolab_customer/features/cart/application/cart_cubit.dart';
import 'package:autolab_customer/features/payments/domain/entities/laropay_purchase.dart';
import 'package:autolab_customer/features/payments/domain/repositories/laropay_purchase_repository.dart';
import 'package:autolab_customer/features/payments/domain/usecases/refresh_laropay_purchase_status.dart';
import 'package:autolab_customer/features/workshops/domain/repositories/workshop_repository.dart';
import 'package:autolab_customer/features/workshops/presentation/pages/workshop_profile_page.dart';
import 'package:autolab_customer/l10n/app_localizations.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockLaropayPurchaseRepository extends Mock
    implements LaropayPurchaseRepository {}

class _MockWorkshopRepository extends Mock implements WorkshopRepository {}

class _MockCartCubit extends MockCubit<CartState> implements CartCubit {}

const _workshopId = 'e2d6f7d0-0a3e-4b3f-9a3e-000000000001';
const _paymentLinkId = '123e4567-e89b-12d3-a456-426614174000';

void main() {
  group('WorkshopProfilePage dialogo de resultado de pago', () {
    late _MockLaropayPurchaseRepository purchaseRepository;
    late _MockWorkshopRepository workshopRepository;
    late _MockCartCubit cartCubit;

    setUp(() {
      purchaseRepository = _MockLaropayPurchaseRepository();
      workshopRepository = _MockWorkshopRepository();
      cartCubit = _MockCartCubit();

      when(() => cartCubit.state).thenReturn(const CartState());
      when(
        () => workshopRepository.getWorkshopById(_workshopId),
      ).thenAnswer((_) async => const Right(null));

      sl.registerFactory<RefreshLaropayPurchaseStatus>(
        () => RefreshLaropayPurchaseStatus(purchaseRepository),
      );
      sl.registerSingleton<WorkshopRepository>(workshopRepository);
    });

    tearDown(() async {
      await sl.unregister<RefreshLaropayPurchaseStatus>();
      await sl.unregister<WorkshopRepository>();
    });

    testWidgets(
      'pago cancelado: muestra mensaje propio y no ofrece reintentar',
      (tester) async {
        when(
          () => purchaseRepository.refreshPurchaseStatus(_paymentLinkId),
        ).thenAnswer((_) async => Right(_purchase(status: 'cancelled')));

        await tester.pumpWidget(_TestApp(router: _buildRouter(), cartCubit: cartCubit));
        await tester.pumpAndSettle();

        expect(find.text('Orden cancelada'), findsOneWidget);
        expect(find.text('Reintentar pago'), findsNothing);
      },
    );

    testWidgets(
      'pago pendiente: ofrece reintentar el mismo link',
      (tester) async {
        when(
          () => purchaseRepository.refreshPurchaseStatus(_paymentLinkId),
        ).thenAnswer((_) async => Right(_purchase(status: 'pending')));

        await tester.pumpWidget(_TestApp(router: _buildRouter(), cartCubit: cartCubit));
        await tester.pumpAndSettle();

        expect(find.text('Reintentar pago'), findsOneWidget);
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
    responseCode: status == 'cancelled' ? '17' : '',
    responseDescription: status == 'cancelled' ? 'CANCELACION DEL CLIENTE' : '',
    rejectReason: '',
    createdAt: DateTime(2026, 8, 14),
    expiresAt: null,
    hasPaymentLink: true,
    linkUrl: Uri.parse('https://laropay.example.com/pay/abc'),
  );
}

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/workshops/$_workshopId?paymentLinkId=$_paymentLinkId',
    routes: [
      GoRoute(
        path: '/workshops/:id',
        builder: (context, state) => WorkshopProfilePage(
          workshopId: state.pathParameters['id']!,
          paymentLinkId: state.uri.queryParameters['paymentLinkId'],
        ),
      ),
      GoRoute(
        path: '/purchases',
        builder: (context, state) => const Scaffold(body: Text('Purchases')),
      ),
    ],
  );
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.router, required this.cartCubit});

  final GoRouter router;
  final CartCubit cartCubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CartCubit>.value(
      value: cartCubit,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }
}
