import 'dart:async';

import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/features/cart/application/cart_cubit.dart';
import 'package:autolab_customer/features/cart/application/cart_persistence.dart';
import 'package:autolab_customer/features/cart/domain/entities/cart_checkout.dart';
import 'package:autolab_customer/features/cart/domain/repositories/cart_repository.dart';
import 'package:autolab_customer/features/cart/domain/repositories/delivery_address_repository.dart';
import 'package:autolab_customer/features/cart/domain/usecases/create_cart_order.dart';
import 'package:autolab_customer/features/cart/domain/usecases/delete_delivery_address.dart';
import 'package:autolab_customer/features/cart/domain/usecases/get_workshop_delivery_fee.dart';
import 'package:autolab_customer/features/cart/domain/usecases/load_delivery_addresses.dart';
import 'package:autolab_customer/features/cart/domain/usecases/save_delivery_address.dart';
import 'package:autolab_customer/features/cart/domain/usecases/set_default_delivery_address.dart';
import 'package:autolab_customer/features/products/application/product_inventory_refresh_notifier.dart';
import 'package:autolab_customer/features/products/domain/entities/product.dart';
import 'package:autolab_customer/features/products/domain/repositories/product_repository.dart';
import 'package:autolab_customer/features/workshops/domain/entities/workshop.dart';
import 'package:autolab_customer/features/workshops/domain/repositories/workshop_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CartCubit', () {
    test(
      'limpia la tarifa de envío al eliminar un carrito de taller',
      () async {
        final cubit = _cartCubit(
          workshopRepository: _FakeWorkshopRepository(
            feesByWorkshopId: const {'workshop-a': 2500, 'workshop-b': 1000},
          ),
        );
        addTearDown(cubit.close);

        cubit
          ..addProduct(_product(id: 'product-a', workshopId: 'workshop-a'))
          ..addProduct(_product(id: 'product-b', workshopId: 'workshop-b'));
        await cubit.refreshWorkshopDeliveryFee(workshopId: 'workshop-a');

        expect(cubit.state.currentWorkshopDeliveryFee, 2500);

        cubit.clearWorkshop('workshop-a');

        expect(cubit.state.items, hasLength(1));
        expect(cubit.state.items.single.product.workshopId, 'workshop-b');
        expect(cubit.state.currentWorkshopDeliveryFee, isNull);
      },
    );

    test(
      'limpia la tarifa si no puede resolver el taller para refrescar envío',
      () async {
        final cubit = _cartCubit(
          workshopRepository: _FakeWorkshopRepository(
            feesByWorkshopId: const {'workshop-a': 2500, 'workshop-b': 1000},
          ),
        );
        addTearDown(cubit.close);

        cubit
          ..addProduct(_product(id: 'product-a', workshopId: 'workshop-a'))
          ..addProduct(_product(id: 'product-b', workshopId: 'workshop-b'));
        await cubit.refreshWorkshopDeliveryFee(workshopId: 'workshop-a');

        expect(cubit.state.currentWorkshopDeliveryFee, 2500);

        final wasRefreshed = await cubit.refreshWorkshopDeliveryFee();

        expect(wasRefreshed, isFalse);
        expect(cubit.state.currentWorkshopDeliveryFee, isNull);
      },
    );

    test('no crea orden con varios talleres sin seleccionar uno', () async {
      final cartRepository = _FakeCartRepository();
      final cubit = _cartCubit(
        cartRepository: cartRepository,
        workshopRepository: _FakeWorkshopRepository(
          feesByWorkshopId: const {'workshop-a': 2500, 'workshop-b': 1000},
        ),
      );
      addTearDown(cubit.close);

      cubit
        ..addProduct(_product(id: 'product-a', workshopId: 'workshop-a'))
        ..addProduct(_product(id: 'product-b', workshopId: 'workshop-b'));

      final result = await cubit.createOrder();

      expect(result, isNull);
      expect(cartRepository.createOrderCallCount, 0);
      expect(cubit.state.checkoutStatus, CartCheckoutStatus.failure);
      expect(cubit.state.checkoutError, 'cart_products_multiple_workshops');
    });

    test('crea orden solo con el taller seleccionado', () async {
      final cartRepository = _FakeCartRepository();
      final productRepository = _FakeProductRepository();
      final cubit = _cartCubit(
        cartRepository: cartRepository,
        productRepository: productRepository,
        workshopRepository: _FakeWorkshopRepository(
          feesByWorkshopId: const {'workshop-a': 2500, 'workshop-b': 1000},
        ),
      );
      addTearDown(cubit.close);

      cubit
        ..addProduct(_product(id: 'product-a', workshopId: 'workshop-a'))
        ..addProduct(_product(id: 'product-b', workshopId: 'workshop-b'));

      final result = await cubit.createOrder(workshopId: 'workshop-b');

      expect(result, isNotNull);
      expect(cartRepository.createOrderCallCount, 1);
      expect(cartRepository.lastRequest?.products, hasLength(1));
      expect(
        cartRepository.lastRequest?.products.single.inventoryItemId,
        'product-b',
      );
      expect(productRepository.invalidatedWorkshopId, 'workshop-b');
    });
  });
}

CartCubit _cartCubit({
  CartRepository? cartRepository,
  ProductRepository? productRepository,
  required WorkshopRepository workshopRepository,
}) {
  final deliveryAddressRepository = _FakeDeliveryAddressRepository();

  return CartCubit(
    loadDeliveryAddresses: LoadDeliveryAddresses(deliveryAddressRepository),
    saveDeliveryAddress: SaveDeliveryAddress(deliveryAddressRepository),
    setDefaultDeliveryAddress: SetDefaultDeliveryAddress(
      deliveryAddressRepository,
    ),
    deleteDeliveryAddress: DeleteDeliveryAddress(deliveryAddressRepository),
    getWorkshopDeliveryFee: GetWorkshopDeliveryFee(workshopRepository),
    createCartOrder: CreateCartOrder(cartRepository ?? _FakeCartRepository()),
    inventoryRefreshNotifier: ProductInventoryRefreshNotifier(),
    productRepository: productRepository ?? _FakeProductRepository(),
    persistence: _MemoryCartPersistence(),
  );
}

Product _product({required String id, required String workshopId}) {
  return Product(
    id: id,
    workshopId: workshopId,
    name: 'Producto $id',
    description: 'Descripción',
    primaryImageUrl: '',
    sellingPrice: 1000,
    currentStock: 10,
    minimumStockAlert: 1,
    itemType: 'product',
    status: 'active',
    requiresAppointment: false,
    skuNumber: id,
    barcode: '',
    categoryName: '',
    brandName: '',
    providerName: '',
    workshopName: 'Taller $workshopId',
    workshopAvatarUrl: '',
    workshopDeliveryFee: workshopId == 'workshop-a' ? 2500 : 1000,
  );
}

class _MemoryCartPersistence extends CartPersistence {
  final _controller = StreamController<CartState>.broadcast();
  CartState? _cart;

  @override
  Stream<CartState> watch() => _controller.stream;

  @override
  Future<CartState?> load() async => _cart;

  @override
  Future<void> save(CartState cart) async {
    _cart = cart;
    _controller.add(cart);
  }

  @override
  Future<void> clear() async {
    _cart = null;
    _controller.add(const CartState());
  }
}

class _FakeCartRepository implements CartRepository {
  var createOrderCallCount = 0;
  CartCheckoutRequest? lastRequest;

  @override
  Future<CartCheckoutResult> createOrder(CartCheckoutRequest request) {
    createOrderCallCount++;
    lastRequest = request;
    return Future.value(
      const CartCheckoutResult(
        orderId: 'order-id',
        orderNumber: 'order-number',
        totalAmount: 0,
      ),
    );
  }
}

class _FakeDeliveryAddressRepository implements DeliveryAddressRepository {
  @override
  Future<void> deleteDeliveryAddress(String addressId) async {}

  @override
  Future<List<CustomerDeliveryAddress>> getDeliveryAddresses() async {
    return const [];
  }

  @override
  Future<CustomerDeliveryAddress> saveDeliveryAddress(
    CustomerDeliveryAddressRequest request, {
    String? addressId,
  }) {
    return Future.value(
      CustomerDeliveryAddress(
        id: addressId ?? 'address-id',
        province: request.province,
        canton: request.canton,
        district: request.district,
        exactAddress: request.exactAddress,
        phone: request.phone,
        isDefault: true,
      ),
    );
  }

  @override
  Future<CustomerDeliveryAddress> setDefaultDeliveryAddress(String addressId) {
    return Future.value(
      CustomerDeliveryAddress(
        id: addressId,
        province: 'Provincia',
        canton: 'Cantón',
        district: 'Distrito',
        exactAddress: 'Dirección',
        phone: '88888888',
        isDefault: true,
      ),
    );
  }
}

class _FakeWorkshopRepository implements WorkshopRepository {
  const _FakeWorkshopRepository({required this.feesByWorkshopId});

  final Map<String, double> feesByWorkshopId;

  @override
  Future<Either<Failure, Workshop?>> getWorkshopById(String id) async {
    return right(
      Workshop(
        id: id,
        name: 'Taller $id',
        description: '',
        locationAddress: '',
        avatarUrl: '',
        coverUrl: '',
        latitude: 10,
        longitude: -84,
        deliveryRadiusKm: 10,
        deliveryFee: feesByWorkshopId[id] ?? 0,
      ),
    );
  }

  @override
  Future<Either<Failure, List<Workshop>>> getWorkshops() {
    throw UnimplementedError();
  }
}

class _FakeProductRepository implements ProductRepository {
  String? invalidatedWorkshopId;

  @override
  Future<Either<Failure, List<Product>>> getActiveProducts() {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<Product>>> getActiveProductsByWorkshop(
    String workshopId,
  ) {
    throw UnimplementedError();
  }

  @override
  void invalidateActiveProductsCache({String? workshopId}) {
    invalidatedWorkshopId = workshopId;
  }
}
