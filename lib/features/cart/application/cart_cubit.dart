import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../products/application/product_inventory_refresh_notifier.dart';
import '../../products/domain/entities/product.dart';
import '../../products/domain/repositories/product_repository.dart';
import '../domain/entities/cart_checkout.dart';
import '../domain/usecases/create_cart_order.dart';
import '../domain/usecases/delete_delivery_address.dart';
import '../domain/usecases/get_workshop_delivery_fee.dart';
import '../domain/usecases/load_delivery_addresses.dart';
import '../domain/usecases/save_delivery_address.dart';
import '../domain/usecases/set_default_delivery_address.dart';
import 'cart_items_service.dart';
import 'cart_persistence.dart';
import 'cart_state.dart';

export 'cart_items_service.dart' show CartAddProductStatus;
export 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit({
    required LoadDeliveryAddresses loadDeliveryAddresses,
    required SaveDeliveryAddress saveDeliveryAddress,
    required SetDefaultDeliveryAddress setDefaultDeliveryAddress,
    required DeleteDeliveryAddress deleteDeliveryAddress,
    required GetWorkshopDeliveryFee getWorkshopDeliveryFee,
    required CreateCartOrder createCartOrder,
    required ProductInventoryRefreshNotifier inventoryRefreshNotifier,
    required ProductRepository productRepository,
    CartItemsService itemsService = const CartItemsService(),
    CartPersistence persistence = const CartPersistence(),
  }) : _loadDeliveryAddresses = loadDeliveryAddresses,
       _saveDeliveryAddress = saveDeliveryAddress,
       _setDefaultDeliveryAddress = setDefaultDeliveryAddress,
       _deleteDeliveryAddress = deleteDeliveryAddress,
       _getWorkshopDeliveryFee = getWorkshopDeliveryFee,
       _createCartOrder = createCartOrder,
       _inventoryRefreshNotifier = inventoryRefreshNotifier,
       _productRepository = productRepository,
       _itemsService = itemsService,
       _persistence = persistence,
       super(const CartState()) {
    _persistenceSubscription = _persistence.watch().listen(_syncPersistedCart);
    _initialization = _initializeCart();
    unawaited(_initialization);
  }

  final LoadDeliveryAddresses _loadDeliveryAddresses;
  final SaveDeliveryAddress _saveDeliveryAddress;
  final SetDefaultDeliveryAddress _setDefaultDeliveryAddress;
  final DeleteDeliveryAddress _deleteDeliveryAddress;
  final GetWorkshopDeliveryFee _getWorkshopDeliveryFee;
  final CreateCartOrder _createCartOrder;
  final ProductInventoryRefreshNotifier _inventoryRefreshNotifier;
  final ProductRepository _productRepository;
  final CartItemsService _itemsService;
  final CartPersistence _persistence;
  late final Future<void> _initialization;

  /// Exposed for tests that need to wait deterministically for the initial
  /// persisted-cart load instead of relying on a fixed delay.
  @visibleForTesting
  Future<void> get initialized => _initialization;

  late final StreamSubscription<CartState> _persistenceSubscription;
  var _sessionVersion = 0;
  var _cartMutationVersion = 0;
  Future<void> _pendingSave = Future.value();

  CartAddProductStatus addProduct(Product product, {int quantity = 1}) {
    final update = _itemsService.addProduct(state, product, quantity: quantity);
    if (!update.wasChanged) {
      return update.status;
    }

    _emitAndSave(
      state.copyWith(
        items: update.items,
        homeDelivery: update.startedNewCart ? false : null,
        homeDeliveryByWorkshop: update.startedNewCart ? const {} : null,
        clearPendingCheckoutResult: true,
      ),
    );
    return update.status;
  }

  Future<CartAddProductStatus> addProductAndPersist(
    Product product, {
    int quantity = 1,
  }) async {
    await _initialization;

    // Delegates to the synchronous addProduct instead of independently
    // re-reading the cart from disk (the previous implementation's bug):
    // CartCubit is a singleton (see app_injection.dart), so `state` is
    // always at least as fresh as disk once _initialization has resolved
    // -- every mutation writes through both. Because addProduct itself has
    // no `await` before its own emit, Dart's single-threaded event loop
    // guarantees two overlapping calls to this method can never interleave
    // their read-modify-write of `state`, so no explicit locking is
    // needed. (The old version's disk re-read broke that guarantee: two
    // concurrent reads could both complete before either write landed, so
    // whichever call's write landed last silently discarded the other's
    // added product.)
    final status = addProduct(product, quantity: quantity);
    await _pendingSave;
    return status;
  }

  bool increaseQuantity(String productId) {
    return _updateQuantity(productId, (quantity) => quantity + 1);
  }

  bool decreaseQuantity(String productId) {
    return _updateQuantity(productId, (quantity) => quantity - 1);
  }

  void removeProduct(String productId) {
    _emitAndSave(
      _stateWithItems(_itemsService.removeProduct(state, productId)),
    );
  }

  void clear() {
    _emitAndSave(
      state.copyWith(
        items: const [],
        homeDelivery: false,
        homeDeliveryByWorkshop: const {},
        clearDeliveryDetails: true,
        checkoutStatus: CartCheckoutStatus.initial,
        clearCheckoutError: true,
        clearPendingCheckoutResult: true,
      ),
    );
  }

  void clearWorkshop(String workshopId) {
    final trimmedWorkshopId = workshopId.trim();
    if (trimmedWorkshopId.isEmpty) {
      return;
    }

    final remainingItems = state.items
        .where((item) => item.product.workshopId.trim() != trimmedWorkshopId)
        .toList(growable: false);
    final homeDeliveryByWorkshop = Map<String, bool>.from(
      state.homeDeliveryByWorkshop,
    )..remove(trimmedWorkshopId);

    _emitAndSave(
      _stateWithItems(remainingItems).copyWith(
        homeDelivery: homeDeliveryByWorkshop.values.any((value) => value),
        homeDeliveryByWorkshop: homeDeliveryByWorkshop,
        clearCurrentWorkshopDeliveryFee: true,
      ),
    );
  }

  Future<void> clearSessionData() async {
    _sessionVersion++;
    _cartMutationVersion++;
    emit(const CartState());

    await _persistence.clear();
  }

  Future<void> reloadPersistedCart() async {
    final sessionVersion = _sessionVersion;
    _cartMutationVersion++;

    final savedCart = await _persistence.load();
    if (savedCart == null || isClosed || sessionVersion != _sessionVersion) {
      return;
    }

    emit(savedCart);
    unawaited(loadDeliveryAddresses(applyDefault: savedCart.homeDelivery));
  }

  @override
  Future<void> close() {
    _persistenceSubscription.cancel();
    return super.close();
  }

  void setHomeDelivery(String workshopId, bool value) {
    final trimmedWorkshopId = workshopId.trim();
    if (trimmedWorkshopId.isEmpty) {
      return;
    }
    final homeDeliveryByWorkshop = Map<String, bool>.from(
      state.homeDeliveryByWorkshop,
    );
    if (value) {
      homeDeliveryByWorkshop[trimmedWorkshopId] = true;
    } else {
      homeDeliveryByWorkshop.remove(trimmedWorkshopId);
    }

    _emitAndSave(
      state.copyWith(
        homeDelivery: homeDeliveryByWorkshop.values.any((value) => value),
        homeDeliveryByWorkshop: homeDeliveryByWorkshop,
        clearPendingCheckoutResult: true,
      ),
    );
    if (value) {
      unawaited(loadDeliveryAddresses(applyDefault: true));
    }
  }

  void setDeliveryAddress(String value) {
    _emitAndSave(
      state.copyWith(deliveryAddress: value, clearPendingCheckoutResult: true),
    );
  }

  void setDeliveryDetails({
    required String province,
    required String canton,
    required String district,
    required String exactAddress,
    required String phoneNumber,
    String? deliveryAddressId,
  }) {
    _emitAndSave(
      state.copyWith(
        selectedDeliveryAddressId:
            deliveryAddressId ?? state.selectedDeliveryAddressId,
        deliveryProvince: province.trim(),
        deliveryCanton: canton.trim(),
        deliveryDistrict: district.trim(),
        deliveryExactAddress: exactAddress.trim(),
        deliveryPhoneNumber: phoneNumber.trim(),
        deliveryAddress: exactAddress.trim(),
        clearPendingCheckoutResult: true,
      ),
    );
  }

  Future<void> loadDeliveryAddresses({bool applyDefault = false}) async {
    try {
      final addresses = await _loadDeliveryAddresses();
      final defaultAddress = addresses
          .where((address) => address.isDefault)
          .firstOrNull;
      final selectedAddress = addresses
          .where((address) => address.id == state.selectedDeliveryAddressId)
          .firstOrNull;
      final addressToApply = applyDefault
          ? selectedAddress ?? defaultAddress ?? addresses.firstOrNull
          : null;

      emit(
        _stateWithAddresses(
          state.copyWith(
            deliveryAddresses: addresses,
            clearDeliveryAddressesError: true,
          ),
          addressToApply,
        ),
      );
    } catch (error) {
      emit(state.copyWith(deliveryAddressesError: _errorKey(error)));
    }
  }

  Future<bool> saveDeliveryAddress({
    required String province,
    required String canton,
    required String district,
    required String exactAddress,
    required String phoneNumber,
  }) async {
    try {
      final selectedId = state.selectedDeliveryAddressId;
      final request = CustomerDeliveryAddressRequest(
        province: province.trim(),
        canton: canton.trim(),
        district: district.trim(),
        exactAddress: exactAddress.trim(),
        phone: phoneNumber.trim(),
      );
      final existingAddress = selectedId.trim().isEmpty
          ? state.deliveryAddresses
                .where((address) => _isSameAddress(address, request))
                .firstOrNull
          : null;

      if (existingAddress != null) {
        await selectDeliveryAddress(existingAddress);
        return true;
      }

      final savedAddress = await _saveDeliveryAddress(
        request,
        addressId: selectedId,
      );

      final addresses = [
        savedAddress,
        ...state.deliveryAddresses.where(
          (address) => address.id != savedAddress.id,
        ),
      ];

      _emitAndSave(
        _stateWithAddresses(
          state.copyWith(
            deliveryAddresses: addresses,
            clearDeliveryAddressesError: true,
          ),
          savedAddress,
        ),
      );
      return true;
    } catch (error) {
      emit(state.copyWith(deliveryAddressesError: _errorKey(error)));
      return false;
    }
  }

  bool _isSameAddress(
    CustomerDeliveryAddress address,
    CustomerDeliveryAddressRequest request,
  ) {
    return _normalizeAddressPart(address.province) ==
            _normalizeAddressPart(request.province) &&
        _normalizeAddressPart(address.canton) ==
            _normalizeAddressPart(request.canton) &&
        _normalizeAddressPart(address.district) ==
            _normalizeAddressPart(request.district) &&
        _normalizeAddressPart(address.exactAddress) ==
            _normalizeAddressPart(request.exactAddress) &&
        _normalizePhone(address.phone) == _normalizePhone(request.phone);
  }

  String _normalizeAddressPart(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  String _normalizePhone(String value) {
    return value.replaceAll(RegExp(r'[\s-]+'), '');
  }

  Future<void> selectDeliveryAddress(CustomerDeliveryAddress address) async {
    _emitAndSave(_stateWithAddresses(state, address));

    try {
      final savedAddress = await _setDefaultDeliveryAddress(address.id);
      final addresses = [
        savedAddress,
        ...state.deliveryAddresses.where((item) => item.id != savedAddress.id),
      ];

      _emitAndSave(
        _stateWithAddresses(
          state.copyWith(
            deliveryAddresses: addresses,
            clearDeliveryAddressesError: true,
          ),
          savedAddress,
        ),
      );
    } catch (error) {
      emit(state.copyWith(deliveryAddressesError: _errorKey(error)));
    }
  }

  Future<bool> deleteDeliveryAddress(String addressId) async {
    try {
      await _deleteDeliveryAddress(addressId);

      final remainingAddresses = state.deliveryAddresses
          .where((address) => address.id != addressId)
          .toList(growable: false);
      final wasSelected = state.selectedDeliveryAddressId == addressId;
      final nextSelectedAddress = wasSelected
          ? remainingAddresses
                    .where((address) => address.isDefault)
                    .firstOrNull ??
                remainingAddresses.firstOrNull
          : remainingAddresses
                .where(
                  (address) => address.id == state.selectedDeliveryAddressId,
                )
                .firstOrNull;

      _emitAndSave(
        _stateWithAddresses(
          state.copyWith(
            deliveryAddresses: remainingAddresses,
            clearDeliveryDetails: wasSelected && remainingAddresses.isEmpty,
            clearDeliveryAddressesError: true,
          ),
          nextSelectedAddress,
        ),
      );
      return true;
    } catch (error) {
      emit(state.copyWith(deliveryAddressesError: _errorKey(error)));
      return false;
    }
  }

  void startNewDeliveryAddress() {
    _emitAndSave(
      state.copyWith(selectedDeliveryAddressId: '', clearDeliveryDetails: true),
    );
  }

  Future<bool> refreshWorkshopDeliveryFee({String? workshopId}) async {
    final targetWorkshopId = workshopId?.trim() ?? state.singleWorkshopId;
    if (targetWorkshopId == null || targetWorkshopId.isEmpty) {
      _emitAndSave(state.copyWith(clearCurrentWorkshopDeliveryFee: true));
      return false;
    }

    try {
      final deliveryFee = await _getWorkshopDeliveryFee(targetWorkshopId);
      _emitAndSave(
        state.copyWith(
          currentWorkshopDeliveryFee: deliveryFee,
          currentWorkshopDeliveryFeeWorkshopId: targetWorkshopId,
        ),
      );
      return true;
    } catch (_) {
      // Keep the persisted item fee as a fallback; checkout RPC remains authoritative.
      return false;
    }
  }

  /// Refreshes cart items' prices against the workshop's current catalog so
  /// the displayed total keeps matching what checkout will actually charge
  /// -- a product's price is otherwise frozen at whatever it was when the
  /// item was added, even if it changes while the item stays in the cart.
  Future<bool> refreshProductPrices({String? workshopId}) async {
    final targetWorkshopId = workshopId?.trim() ?? state.singleWorkshopId;
    if (targetWorkshopId == null || targetWorkshopId.isEmpty) {
      return false;
    }

    final products = await _fetchWorkshopProducts(targetWorkshopId);
    if (products == null) {
      return false;
    }

    final productsById = {for (final product in products) product.id: product};

    var wasChanged = false;
    final refreshedItems = state.items
        .map((item) {
          if (item.product.workshopId.trim() != targetWorkshopId) {
            return item;
          }

          final freshProduct = productsById[item.product.id];
          // Product has no == override, so comparing whole objects would
          // always report a change (a freshly-fetched instance is never
          // identical to the one already in the cart) and trigger a save +
          // rebuild on every refresh even when nothing actually changed.
          // Comparing the field this refresh exists to correct avoids that.
          if (freshProduct == null ||
              freshProduct.sellingPrice == item.product.sellingPrice) {
            return item;
          }

          wasChanged = true;
          return item.copyWith(product: freshProduct);
        })
        .toList(growable: false);

    if (wasChanged) {
      _emitAndSave(state.copyWith(items: refreshedItems));
    }
    return true;
  }

  /// Fetches [workshopId]'s current catalog, bypassing the repository's own
  /// cache (only invalidated after a successful checkout) so this always
  /// reflects the live price instead of the same stale value this refresh
  /// exists to correct. Returns null on any failure -- the caller falls
  /// back to whatever prices are already in the cart, since checkout only
  /// ever charges by inventoryItemId and the server remains authoritative
  /// regardless.
  Future<List<Product>?> _fetchWorkshopProducts(String workshopId) async {
    try {
      _productRepository.invalidateActiveProductsCache(workshopId: workshopId);
      final result = await _productRepository.getActiveProductsByWorkshop(
        workshopId,
      );
      return result.fold<List<Product>?>((_) => null, (products) => products);
    } catch (_) {
      return null;
    }
  }

  Future<CartCheckoutResult?> createOrder({String? workshopId}) async {
    if (state.items.isEmpty || state.checkoutStatus.isLoading) {
      return null;
    }

    final targetWorkshopId = workshopId?.trim();
    final resolvedWorkshopId =
        targetWorkshopId == null || targetWorkshopId.isEmpty
        ? state.singleWorkshopId
        : targetWorkshopId;

    if (resolvedWorkshopId == null || resolvedWorkshopId.isEmpty) {
      emit(
        state.copyWith(
          checkoutStatus: CartCheckoutStatus.failure,
          checkoutError: 'cart_products_multiple_workshops',
          clearPendingCheckoutResult: true,
        ),
      );
      return null;
    }

    final checkoutItems = state.items
        .where((item) => item.product.workshopId.trim() == resolvedWorkshopId)
        .toList(growable: false);

    if (checkoutItems.isEmpty) {
      return null;
    }

    if (state.homeDeliveryFor(resolvedWorkshopId) &&
        !state.hasCompleteDeliveryDetails) {
      emit(
        state.copyWith(
          checkoutStatus: CartCheckoutStatus.failure,
          checkoutError: 'cart_delivery_details_required',
        ),
      );
      return null;
    }

    final checkoutWorkshopIds = checkoutItems
        .map((item) => item.product.workshopId.trim())
        .toSet();

    if (checkoutWorkshopIds.contains('') ||
        checkoutWorkshopIds.length != 1 ||
        !checkoutWorkshopIds.contains(resolvedWorkshopId)) {
      emit(
        state.copyWith(
          checkoutStatus: CartCheckoutStatus.failure,
          checkoutError: 'cart_products_multiple_workshops',
          clearPendingCheckoutResult: true,
        ),
      );
      return null;
    }

    emit(
      state.copyWith(
        checkoutStatus: CartCheckoutStatus.loading,
        clearCheckoutError: true,
      ),
    );

    try {
      final pendingResult = state.pendingCheckoutResult;
      if (pendingResult != null) {
        emit(state.copyWith(checkoutStatus: CartCheckoutStatus.initial));
        return pendingResult;
      }

      await refreshWorkshopDeliveryFee(workshopId: resolvedWorkshopId);
      await refreshProductPrices(workshopId: resolvedWorkshopId);
      final result = await _createCartOrder(
        CartCheckoutRequest(
          products: checkoutItems
              .map(
                (item) => CartCheckoutProduct(
                  inventoryItemId: item.product.id,
                  quantity: item.quantity,
                ),
              )
              .toList(growable: false),
          homeDelivery: state.homeDeliveryFor(resolvedWorkshopId),
          deliveryDetails: state.homeDeliveryFor(resolvedWorkshopId)
              ? CartCheckoutDeliveryDetails(
                  province: state.deliveryProvince,
                  canton: state.deliveryCanton,
                  district: state.deliveryDistrict,
                  exactAddress: state.deliveryExactAddress,
                  phone: state.deliveryPhoneNumber,
                )
              : null,
        ),
      );

      _productRepository.invalidateActiveProductsCache(
        workshopId: resolvedWorkshopId,
      );
      _inventoryRefreshNotifier.notify();
      // Persist immediately and WAIT for the write (not _emitAndSave's
      // fire-and-forget save): if the app is killed right after the order
      // is created on the server -- e.g. backgrounded while Laropay's
      // external browser has focus -- this guard must already be on disk
      // before the caller can proceed to launch that browser, or the same
      // duplicate-order race just reopens in the gap before the write lands.
      final nextState = state.copyWith(
        checkoutStatus: CartCheckoutStatus.initial,
        pendingCheckoutResult: result,
      );
      _cartMutationVersion++;
      emit(nextState);
      await _enqueueSave(nextState);
      return result;
    } catch (error) {
      emit(
        state.copyWith(
          checkoutStatus: CartCheckoutStatus.failure,
          checkoutError: _errorKey(error),
          clearPendingCheckoutResult: true,
        ),
      );
      return null;
    }
  }

  void resetCheckoutStatus() {
    emit(
      state.copyWith(
        checkoutStatus: CartCheckoutStatus.initial,
        clearCheckoutError: true,
      ),
    );
  }

  bool _updateQuantity(String productId, int Function(int quantity) update) {
    final result = _itemsService.updateQuantity(state, productId, update);
    if (!result.wasChanged) {
      return false;
    }

    _emitAndSave(_stateWithItems(result.items));
    return true;
  }

  String _errorKey(Object error) {
    if (error is CartCheckoutException) {
      return error.message;
    }

    return 'cart_unexpected_error';
  }

  CartState _stateWithAddresses(
    CartState current,
    CustomerDeliveryAddress? address,
  ) {
    if (address == null) {
      return current;
    }

    return current.copyWith(
      selectedDeliveryAddressId: address.id,
      deliveryProvince: address.province,
      deliveryCanton: address.canton,
      deliveryDistrict: address.district,
      deliveryExactAddress: address.exactAddress,
      deliveryPhoneNumber: address.phone,
      deliveryAddress: address.exactAddress,
      clearPendingCheckoutResult: true,
    );
  }

  CartState _stateWithItems(List<CartItem> items) {
    if (items.isEmpty) {
      return state.copyWith(
        items: items,
        homeDelivery: false,
        homeDeliveryByWorkshop: const {},
        clearCurrentWorkshopDeliveryFee: true,
        clearPendingCheckoutResult: true,
      );
    }

    return state.copyWith(items: items, clearPendingCheckoutResult: true);
  }

  Future<void> _loadSavedCart({
    required int sessionVersion,
    required int mutationVersion,
  }) async {
    final savedCart = await _persistence.load();
    if (savedCart == null ||
        sessionVersion != _sessionVersion ||
        mutationVersion != _cartMutationVersion) {
      return;
    }

    emit(savedCart);
  }

  Future<void> _initializeCart() async {
    final sessionVersion = _sessionVersion;
    final mutationVersion = _cartMutationVersion;

    await _loadSavedCart(
      sessionVersion: sessionVersion,
      mutationVersion: mutationVersion,
    );
    if (sessionVersion != _sessionVersion ||
        mutationVersion != _cartMutationVersion) {
      return;
    }

    await loadDeliveryAddresses(applyDefault: state.homeDelivery);
  }

  void _syncPersistedCart(CartState persistedState) {
    if (isClosed || persistedState == state) {
      return;
    }

    _cartMutationVersion++;
    emit(
      persistedState.copyWith(
        deliveryAddresses: state.deliveryAddresses,
        deliveryAddressesError: state.deliveryAddressesError,
        checkoutStatus: state.checkoutStatus,
        checkoutError: state.checkoutError,
        pendingCheckoutResult: state.pendingCheckoutResult,
      ),
    );
  }

  void _emitAndSave(CartState nextState) {
    _cartMutationVersion++;
    emit(nextState);
    unawaited(_enqueueSave(nextState));
  }

  Future<void> _enqueueSave(CartState cart) {
    _pendingSave = _pendingSave
        .catchError((_) {
          // La persistencia local es best-effort; mantenga viva la cola.
        })
        .then((_) => _persistence.save(cart));

    return _pendingSave;
  }
}
