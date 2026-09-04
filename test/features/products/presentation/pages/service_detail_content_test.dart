import 'package:autolab_customer/core/di/app_injection.dart';
import 'package:autolab_customer/features/products/domain/entities/product.dart';
import 'package:autolab_customer/features/products/domain/repositories/favorite_inventory_items_repository.dart';
import 'package:autolab_customer/features/products/domain/usecases/get_additional_products_by_workshop.dart';
import 'package:autolab_customer/features/products/presentation/pages/service_detail_content.dart';
import 'package:autolab_customer/l10n/app_localizations.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFavoriteInventoryItemsRepository extends Mock
    implements FavoriteInventoryItemsRepository {}

class _MockGetAdditionalProductsByWorkshop extends Mock
    implements GetAdditionalProductsByWorkshop {}

void main() {
  group('ServiceDetailContent selector de cantidad', () {
    late _MockFavoriteInventoryItemsRepository favoriteRepository;
    late _MockGetAdditionalProductsByWorkshop getAdditionalProducts;

    setUp(() {
      favoriteRepository = _MockFavoriteInventoryItemsRepository();
      getAdditionalProducts = _MockGetAdditionalProductsByWorkshop();
      sl.registerFactory<GetAdditionalProductsByWorkshop>(
        () => getAdditionalProducts,
      );
    });

    tearDown(() async {
      await sl.unregister<GetAdditionalProductsByWorkshop>();
    });

    Future<void> useTallViewport(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    testWidgets('bloquea el "+" al llegar al stock disponible del producto', (
      tester,
    ) async {
      await useTallViewport(tester);
      final service = _service();
      final relatedProduct = _relatedProduct(currentStock: 2);

      when(
        () => favoriteRepository.isFavoriteInventoryItem(service.id),
      ).thenAnswer((_) async => false);
      when(
        () => getAdditionalProducts(service.workshopId),
      ).thenAnswer((_) async => Right([relatedProduct]));

      await tester.pumpWidget(
        _TestApp(
          child: ServiceDetailContent(
            service: service,
            favoriteRepository: favoriteRepository,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('SIGUIENTE'));
      await tester.pumpAndSettle();

      expect(find.text('Filtro de aceite'), findsOneWidget);

      // Primer tap: 0 -> 1 unidad (aparece el control de cantidad).
      await tester.tap(find.byIcon(Icons.add_circle_outline_rounded));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);

      // Segundo tap: 1 -> 2 unidades (llega exacto al stock disponible).
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
      expect(find.text('2'), findsOneWidget);

      // Tercer tap: ya no hay más stock, debe bloquear y avisar.
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();

      expect(find.text('2'), findsOneWidget);
      expect(
        find.text('No hay más unidades disponibles de este producto.'),
        findsOneWidget,
      );
    });

    testWidgets('permite reducir la cantidad sin activar el aviso de stock', (
      tester,
    ) async {
      await useTallViewport(tester);
      final service = _service();
      final relatedProduct = _relatedProduct(currentStock: 5);

      when(
        () => favoriteRepository.isFavoriteInventoryItem(service.id),
      ).thenAnswer((_) async => false);
      when(
        () => getAdditionalProducts(service.workshopId),
      ).thenAnswer((_) async => Right([relatedProduct]));

      await tester.pumpWidget(
        _TestApp(
          child: ServiceDetailContent(
            service: service,
            favoriteRepository: favoriteRepository,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('SIGUIENTE'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_circle_outline_rounded));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
      expect(find.text('2'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
      expect(
        find.text('No hay más unidades disponibles de este producto.'),
        findsNothing,
      );
    });
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }
}

Product _service() {
  return const Product(
    id: 'service-1',
    workshopId: 'workshop-1',
    name: 'Cambio de aceite',
    description: 'Cambio de aceite de motor',
    primaryImageUrl: '',
    sellingPrice: 25000,
    currentStock: null,
    minimumStockAlert: null,
    itemType: 'service',
    status: 'active',
    requiresAppointment: true,
    skuNumber: 'SKU-SERVICE-1',
    barcode: '',
    categoryName: 'Servicios',
    brandName: 'Autolab',
    providerName: 'Autolab',
    workshopName: 'Autolab Centro',
    workshopAvatarUrl: '',
  );
}

Product _relatedProduct({required int currentStock}) {
  return Product(
    id: 'product-1',
    workshopId: 'workshop-1',
    name: 'Filtro de aceite',
    description: 'Filtro de aceite compatible',
    primaryImageUrl: '',
    sellingPrice: 6500,
    currentStock: currentStock,
    minimumStockAlert: 1,
    itemType: 'product',
    status: 'active',
    requiresAppointment: false,
    skuNumber: 'SKU-PRODUCT-1',
    barcode: 'BAR-1',
    categoryName: 'Filtros',
    brandName: 'Autolab',
    providerName: 'Autolab',
    workshopName: 'Autolab Centro',
    workshopAvatarUrl: '',
  );
}
