import 'dart:async';

import 'package:autolab_customer/features/cart/application/cart_cubit.dart';
import 'package:autolab_customer/features/products/domain/entities/product.dart';
import 'package:autolab_customer/features/products/domain/repositories/favorite_inventory_items_repository.dart';
import 'package:autolab_customer/features/products/presentation/pages/physical_product_detail_content.dart';
import 'package:autolab_customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockFavoriteInventoryItemsRepository extends Mock
    implements FavoriteInventoryItemsRepository {}

class _MockCartCubit extends Mock implements CartCubit {}

void main() {
  setUpAll(() {
    registerFallbackValue(_product());
  });

  testWidgets('renders with injected favorite repository', (tester) async {
    final favoriteRepository = _MockFavoriteInventoryItemsRepository();
    final cartCubit = _MockCartCubit();

    when(
      () => favoriteRepository.isFavoriteInventoryItem('product-1'),
    ).thenAnswer((_) async => false);
    when(() => cartCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => cartCubit.state).thenReturn(const CartState());

    await tester.pumpWidget(
      BlocProvider<CartCubit>.value(
        value: cartCubit,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: PhysicalProductDetailContent(
            product: _product(),
            favoriteRepository: favoriteRepository,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Escobillas premium'), findsOneWidget);
    verify(
      () => favoriteRepository.isFavoriteInventoryItem('product-1'),
    ).called(1);
  });

  testWidgets('redirects to login when favorite requires auth', (tester) async {
    final favoriteRepository = _MockFavoriteInventoryItemsRepository();
    final cartCubit = _MockCartCubit();

    when(
      () => favoriteRepository.isFavoriteInventoryItem('product-1'),
    ).thenAnswer((_) async => false);
    when(
      () => favoriteRepository.toggleFavoriteInventoryItem(
        'product-1',
        itemType: 'product',
      ),
    ).thenThrow(const FavoriteInventoryItemsAuthException());
    when(() => cartCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => cartCubit.state).thenReturn(const CartState());

    final router = GoRouter(
      initialLocation: '/product',
      routes: [
        GoRoute(
          path: '/product',
          builder: (context, state) => BlocProvider<CartCubit>.value(
            value: cartCubit,
            child: PhysicalProductDetailContent(
              product: _product(),
              favoriteRepository: favoriteRepository,
            ),
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const Scaffold(body: Text('Login')),
        ),
      ],
    );

    await tester.pumpWidget(_TestApp(router: router));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.favorite_border_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets(
    'deshabilita los botones de compra mientras la operación está en curso',
    (tester) async {
      // Los botones quedan al final de un CustomScrollView; sin esto no
      // se construyen dentro del viewport chico por defecto del test.
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final favoriteRepository = _MockFavoriteInventoryItemsRepository();
      final cartCubit = _MockCartCubit();
      final addCompleter = Completer<CartAddProductStatus>();

      when(
        () => favoriteRepository.isFavoriteInventoryItem('product-1'),
      ).thenAnswer((_) async => false);
      when(() => cartCubit.stream).thenAnswer((_) => const Stream.empty());
      when(() => cartCubit.state).thenReturn(const CartState());
      when(
        () => cartCubit.addProductAndPersist(
          any(),
          quantity: any(named: 'quantity'),
        ),
      ).thenAnswer((_) => addCompleter.future);

      await tester.pumpWidget(
        BlocProvider<CartCubit>.value(
          value: cartCubit,
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: PhysicalProductDetailContent(
              product: _product(),
              favoriteRepository: favoriteRepository,
            ),
          ),
        ),
      );
      await tester.pump();

      // ElevatedButton.icon/OutlinedButton.icon build a private subtype, so
      // find.widgetWithText's exact-type matching (like find.byType) never
      // matches them -- match by predicate (which respects `is`) instead.
      final buyButtonFinder = find.ancestor(
        of: find.text('Comprar'),
        matching: find.byWidgetPredicate((widget) => widget is ElevatedButton),
      );
      final addToCartButtonFinder = find.ancestor(
        of: find.text('Agregar al carrito'),
        matching: find.byWidgetPredicate((widget) => widget is OutlinedButton),
      );

      await tester.tap(buyButtonFinder);
      await tester.pump();

      // Mientras addProductAndPersist sigue pendiente, ambos botones deben
      // quedar deshabilitados -- no solo el que se tocó, porque un tap en
      // el otro botón mientras este sigue en vuelo es exactamente el
      // escenario de doble-tap que CartCubit ya protege a nivel de datos,
      // pero que además debería reflejarse visualmente.
      expect(tester.widget<ElevatedButton>(buyButtonFinder).onPressed, isNull);
      expect(
        tester.widget<OutlinedButton>(addToCartButtonFinder).onPressed,
        isNull,
      );

      // Se completa con un status que NO navega (a diferencia de `added`,
      // que dispara context.go y requeriría un GoRouter real montado en
      // este test) -- lo único que interesa acá es que los botones se
      // vuelvan a habilitar una vez que la llamada termina.
      addCompleter.complete(CartAddProductStatus.stockLimitReached);
      await tester.pumpAndSettle();

      expect(
        tester.widget<ElevatedButton>(buyButtonFinder).onPressed,
        isNotNull,
      );
    },
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

Product _product() {
  return const Product(
    id: 'product-1',
    workshopId: 'workshop-1',
    name: 'Escobillas premium',
    description: 'Escobillas de prueba',
    primaryImageUrl: '',
    sellingPrice: 12000,
    currentStock: 3,
    minimumStockAlert: 1,
    itemType: 'product',
    status: 'active',
    requiresAppointment: false,
    skuNumber: 'SKU-1',
    barcode: 'BAR-1',
    categoryName: 'Accesorios',
    brandName: 'Autolab',
    providerName: 'Autolab',
    workshopName: 'Autolab Centro',
    workshopAvatarUrl: '',
  );
}
