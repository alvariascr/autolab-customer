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
      expect(cubit.state.checkoutStatus, CartCheckoutStatus.initial);
    });

    test(
      'no queda bloqueado en loading tras crear la orden, permite reintentar',
      () async {
        final cartRepository = _FakeCartRepository();
        final cubit = _cartCubit(
          cartRepository: cartRepository,
          workshopRepository: _FakeWorkshopRepository(
            feesByWorkshopId: const {'workshop-a': 2500},
          ),
        );
        addTearDown(cubit.close);

        cubit.addProduct(_product(id: 'product-a', workshopId: 'workshop-a'));

        final firstResult = await cubit.createOrder(workshopId: 'workshop-a');
        expect(firstResult, isNotNull);
        expect(cubit.state.checkoutStatus.isLoading, isFalse);

        cubit.addProduct(_product(id: 'product-b', workshopId: 'workshop-a'));
        final secondResult = await cubit.createOrder(workshopId: 'workshop-a');

        expect(secondResult, isNotNull);
        expect(cartRepository.createOrderCallCount, 2);
        expect(cubit.state.checkoutStatus.isLoading, isFalse);
      },
    );

    test('no crea una orden duplicada si la app reinicia justo después de '
        'crear la orden pero antes de vaciar el carrito', () async {
      final cartRepository = _FakeCartRepository();
      final sharedPersistence = _MemoryCartPersistence();
      final firstCubit = _cartCubit(
        cartRepository: cartRepository,
        workshopRepository: _FakeWorkshopRepository(
          feesByWorkshopId: const {'workshop-a': 2500},
        ),
        persistence: sharedPersistence,
      );

      firstCubit.addProduct(
        _product(id: 'product-a', workshopId: 'workshop-a'),
      );
      final firstResult = await firstCubit.createOrder(
        workshopId: 'workshop-a',
      );
      expect(firstResult, isNotNull);
      expect(cartRepository.createOrderCallCount, 1);

      // Simula que la app murió justo acá -- la orden ya se creó en el
      // servidor, pero el carrito nunca llegó a vaciarse. Un cubit nuevo
      // (el proceso relanzado) carga el mismo carrito persistido.
      final relaunchedCubit = _cartCubit(
        cartRepository: cartRepository,
        workshopRepository: _FakeWorkshopRepository(
          feesByWorkshopId: const {'workshop-a': 2500},
        ),
        persistence: sharedPersistence,
      );
      addTearDown(() async {
        await firstCubit.close();
        await relaunchedCubit.close();
      });
      await relaunchedCubit.initialized;

      final retryResult = await relaunchedCubit.createOrder(
        workshopId: 'workshop-a',
      );

      expect(retryResult, firstResult);
      expect(
        cartRepository.createOrderCallCount,
        1,
        reason: 'reintentar tras un reinicio no debe crear una segunda orden',
      );
    });

    test('actualiza el precio de un item si cambió mientras seguía en el '
        'carrito', () async {
      final productRepository = _FakeProductRepository();
      final cubit = _cartCubit(
        productRepository: productRepository,
        workshopRepository: _FakeWorkshopRepository(
          feesByWorkshopId: const {'workshop-a': 2500},
        ),
      );
      addTearDown(cubit.close);

      cubit.addProduct(
        _product(id: 'product-a', workshopId: 'workshop-a', price: 1000),
      );
      expect(cubit.state.total, 1000);

      // El precio del producto sube en el catálogo del taller mientras
      // el item sigue en el carrito -- el total mostrado no debe seguir
      // congelado en el precio con el que se agregó.
      productRepository.activeProductsByWorkshop['workshop-a'] = [
        _product(id: 'product-a', workshopId: 'workshop-a', price: 1500),
      ];

      final wasRefreshed = await cubit.refreshProductPrices(
        workshopId: 'workshop-a',
      );

      expect(wasRefreshed, isTrue);
      expect(cubit.state.items.single.product.sellingPrice, 1500);
      expect(cubit.state.total, 1500);
    });

    test(
      'conserva el precio guardado si no puede refrescar el catálogo',
      () async {
        final cubit = _cartCubit(
          productRepository: _FakeProductRepository(),
          workshopRepository: _FakeWorkshopRepository(
            feesByWorkshopId: const {'workshop-a': 2500},
          ),
        );
        addTearDown(cubit.close);

        cubit.addProduct(
          _product(id: 'product-a', workshopId: 'workshop-a', price: 1000),
        );

        // _FakeProductRepository no tiene nada cargado para este taller,
        // asi que getActiveProductsByWorkshop lanza -- el refresh debe
        // fallar sin corromper el item ya guardado.
        final wasRefreshed = await cubit.refreshProductPrices(
          workshopId: 'workshop-a',
        );

        expect(wasRefreshed, isFalse);
        expect(cubit.state.items.single.product.sellingPrice, 1000);
        expect(cubit.state.total, 1000);
      },
    );

    test('conserva el ítem sin modificar si el catálogo devuelto ya no '
        'incluye el producto', () async {
      final productRepository = _FakeProductRepository();
      final cubit = _cartCubit(
        productRepository: productRepository,
        workshopRepository: _FakeWorkshopRepository(
          feesByWorkshopId: const {'workshop-a': 2500},
        ),
      );
      addTearDown(cubit.close);

      cubit.addProduct(
        _product(id: 'product-a', workshopId: 'workshop-a', price: 1000),
      );

      // El taller respondió con éxito, pero 'product-a' ya no está en su
      // catálogo activo (se desactivó/eliminó) -- a diferencia de una
      // falla de red, esto sí cuenta como refresh exitoso, pero el item
      // debe conservarse tal cual estaba, no desaparecer del carrito.
      productRepository.activeProductsByWorkshop['workshop-a'] = [];

      final wasRefreshed = await cubit.refreshProductPrices(
        workshopId: 'workshop-a',
      );

      expect(wasRefreshed, isTrue);
      expect(cubit.state.items.single.product.sellingPrice, 1000);
      expect(cubit.state.total, 1000);
    });

    test('no reemite el estado si el precio del catálogo no cambió', () async {
      final productRepository = _FakeProductRepository();
      final cubit = _cartCubit(
        productRepository: productRepository,
        workshopRepository: _FakeWorkshopRepository(
          feesByWorkshopId: const {'workshop-a': 2500},
        ),
      );
      addTearDown(cubit.close);

      cubit.addProduct(
        _product(id: 'product-a', workshopId: 'workshop-a', price: 1000),
      );
      // Misma placa de precio (1000), pero una instancia de Product
      // distinta a la que ya está en el carrito -- Product no tiene ==
      // propio, así que comparar los objetos completos siempre marcaría
      // esto como "cambiado" aunque el precio sea idéntico.
      productRepository.activeProductsByWorkshop['workshop-a'] = [
        _product(id: 'product-a', workshopId: 'workshop-a', price: 1000),
      ];
      final itemsBeforeRefresh = cubit.state.items;

      final wasRefreshed = await cubit.refreshProductPrices(
        workshopId: 'workshop-a',
      );

      expect(wasRefreshed, isTrue);
      expect(
        identical(itemsBeforeRefresh, cubit.state.items),
        isTrue,
        reason:
            'sin cambio real de precio no debería emitirse (ni guardarse) '
            'un nuevo estado',
      );
    });

    test('solo actualiza los precios del taller pedido, no los de otro '
        'taller en el mismo carrito', () async {
      final productRepository = _FakeProductRepository();
      final cubit = _cartCubit(
        productRepository: productRepository,
        workshopRepository: _FakeWorkshopRepository(
          feesByWorkshopId: const {'workshop-a': 2500, 'workshop-b': 1000},
        ),
      );
      addTearDown(cubit.close);

      cubit
        ..addProduct(
          _product(id: 'product-a', workshopId: 'workshop-a', price: 1000),
        )
        ..addProduct(
          _product(id: 'product-b', workshopId: 'workshop-b', price: 2000),
        );

      productRepository.activeProductsByWorkshop['workshop-a'] = [
        _product(id: 'product-a', workshopId: 'workshop-a', price: 1500),
      ];

      await cubit.refreshProductPrices(workshopId: 'workshop-a');

      final itemA = cubit.state.items.singleWhere(
        (item) => item.product.id == 'product-a',
      );
      final itemB = cubit.state.items.singleWhere(
        (item) => item.product.id == 'product-b',
      );
      expect(itemA.product.sellingPrice, 1500);
      expect(
        itemB.product.sellingPrice,
        2000,
        reason:
            'el item de workshop-b no se pidio refrescar y no deberia '
            'cambiar aunque el repositorio no tenga nada configurado para '
            'workshop-b',
      );
    });

    test('no pierde productos si se agregan en paralelo', () async {
      final cubit = _cartCubit(
        workshopRepository: _FakeWorkshopRepository(
          feesByWorkshopId: const {'workshop-a': 2500},
        ),
      );
      addTearDown(cubit.close);
      await cubit.initialized;

      // Simula el doble tap real en "Comprar": ninguna llamada espera a
      // la otra, ambas arrancan antes de que la primera termine de
      // guardar.
      final results = await Future.wait([
        cubit.addProductAndPersist(
          _product(id: 'product-a', workshopId: 'workshop-a'),
        ),
        cubit.addProductAndPersist(
          _product(id: 'product-b', workshopId: 'workshop-a'),
        ),
      ]);

      expect(results, everyElement(CartAddProductStatus.added));
      expect(cubit.state.items.map((item) => item.product.id).toSet(), {
        'product-a',
        'product-b',
      }, reason: 'ambos productos deben sobrevivir, ninguno se pisa');
    });
  });
}

CartCubit _cartCubit({
  CartRepository? cartRepository,
  ProductRepository? productRepository,
  required WorkshopRepository workshopRepository,
  CartPersistence? persistence,
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
    persistence: persistence ?? _MemoryCartPersistence(),
  );
}

Product _product({
  required String id,
  required String workshopId,
  double price = 1000,
}) {
  return Product(
    id: id,
    workshopId: workshopId,
    name: 'Producto $id',
    description: 'Descripción',
    primaryImageUrl: '',
    sellingPrice: price,
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

/// Round-trips every saved cart through toJson/fromJson (like the real
/// SharedPreferences-backed persistence would), instead of just keeping the
/// in-memory CartState object around -- otherwise a field that toJson forgets
/// to serialize would still "survive" in these tests via object identity,
/// hiding exactly the kind of bug this fake exists to catch.
class _MemoryCartPersistence extends CartPersistence {
  final _controller = StreamController<CartState>.broadcast();
  Map<String, dynamic>? _cartJson;

  @override
  Stream<CartState> watch() => _controller.stream;

  @override
  Future<CartState?> load() async {
    final cartJson = _cartJson;
    return cartJson == null ? null : CartState.fromJson(cartJson);
  }

  @override
  Future<void> save(CartState cart) async {
    _cartJson = cart.toJson();
    _controller.add(cart);
  }

  @override
  Future<void> clear() async {
    _cartJson = null;
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

  /// Products refreshProductPrices() should see as "the current catalog"
  /// for a given workshop. A workshop with nothing configured here behaves
  /// like a repository call that fails, matching a real network error.
  final activeProductsByWorkshop = <String, List<Product>>{};

  @override
  Future<Either<Failure, List<Product>>> getActiveProducts() {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<Product>>> getActiveProductsByWorkshop(
    String workshopId,
  ) async {
    final products = activeProductsByWorkshop[workshopId];
    if (products == null) {
      throw StateError('No products configured for workshop $workshopId');
    }
    return right(products);
  }

  @override
  void invalidateActiveProductsCache({String? workshopId}) {
    invalidatedWorkshopId = workshopId;
  }
}
