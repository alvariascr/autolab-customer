import 'package:autolab_customer/features/cart/application/cart_cubit.dart';
import 'package:autolab_customer/features/products/domain/entities/product.dart';
import 'package:autolab_customer/features/products/domain/repositories/favorite_inventory_items_repository.dart';
import 'package:autolab_customer/features/products/presentation/pages/physical_product_detail_content.dart';
import 'package:autolab_customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFavoriteInventoryItemsRepository extends Mock
    implements FavoriteInventoryItemsRepository {}

class _MockCartCubit extends Mock implements CartCubit {}

void main() {
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
