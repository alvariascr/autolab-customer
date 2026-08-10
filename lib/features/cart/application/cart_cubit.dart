import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../products/domain/entities/product.dart';
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

export 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit({
    required LoadDeliveryAddresses loadDeliveryAddresses,
    required SaveDeliveryAddress saveDeliveryAddress,
    required SetDefaultDeliveryAddress setDefaultDeliveryAddress,
    required DeleteDeliveryAddress deleteDeliveryAddress,
    required GetWorkshopDeliveryFee getWorkshopDeliveryFee,
    required CreateCartOrder createCartOrder,
    CartItemsService itemsService = const CartItemsService(),
    CartPersistence persistence = const CartPersistence(),
  }) : _loadDeliveryAddresses = loadDeliveryAddresses,
       _saveDeliveryAddress = saveDeliveryAddress,
       _setDefaultDeliveryAddress = setDefaultDeliveryAddress,
       _deleteDeliveryAddress = deleteDeliveryAddress,
       _getWorkshopDeliveryFee = getWorkshopDeliveryFee,
       _createCartOrder = createCartOrder,
       _itemsService = itemsService,
       _persistence = persistence,
       super(const CartState()) {
    unawaited(_initializeCart());
  }

  final LoadDeliveryAddresses _loadDeliveryAddresses;
  final SaveDeliveryAddress _saveDeliveryAddress;
  final SetDefaultDeliveryAddress _setDefaultDeliveryAddress;
  final DeleteDeliveryAddress _deleteDeliveryAddress;
  final GetWorkshopDeliveryFee _getWorkshopDeliveryFee;
  final CreateCartOrder _createCartOrder;
  final CartItemsService _itemsService;
  final CartPersistence _persistence;
  var _sessionVersion = 0;
  var _cartMutationVersion = 0;
  Future<void> _pendingSave = Future.value();

  bool addProduct(Product product, {int quantity = 1}) {
    final update = _itemsService.addProduct(state, product, quantity: quantity);
    if (!update.wasChanged) {
      return false;
    }

    _emitAndSave(
      state.copyWith(
        items: update.items,
        homeDelivery: update.startedNewCart ? false : null,
      ),
    );
    return true;
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
        clearDeliveryDetails: true,
        checkoutStatus: CartCheckoutStatus.initial,
        clearCheckoutError: true,
      ),
    );
  }

  Future<void> clearSessionData() async {
    _sessionVersion++;
    _cartMutationVersion++;
    emit(const CartState());

    await _persistence.clear();
  }

  void setHomeDelivery(bool value) {
    _emitAndSave(state.copyWith(homeDelivery: value));
    if (value) {
      unawaited(loadDeliveryAddresses(applyDefault: true));
    }
  }

  void setDeliveryAddress(String value) {
    _emitAndSave(state.copyWith(deliveryAddress: value));
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
      final savedAddress = await _saveDeliveryAddress(
        CustomerDeliveryAddressRequest(
          province: province,
          canton: canton,
          district: district,
          exactAddress: exactAddress,
          phone: phoneNumber,
        ),
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

  Future<void> refreshWorkshopDeliveryFee() async {
    final workshopId = state.singleWorkshopId;
    if (workshopId == null) {
      return;
    }

    try {
      final deliveryFee = await _getWorkshopDeliveryFee(workshopId);
      _emitAndSave(state.copyWith(currentWorkshopDeliveryFee: deliveryFee));
    } catch (_) {
      // Keep the persisted item fee as a fallback; checkout RPC remains authoritative.
    }
  }

  Future<CartCheckoutResult?> createOrder() async {
    if (state.items.isEmpty || state.checkoutStatus.isLoading) {
      return null;
    }

    if (state.homeDelivery && !state.hasCompleteDeliveryDetails) {
      emit(
        state.copyWith(
          checkoutStatus: CartCheckoutStatus.failure,
          checkoutError: 'cart_delivery_details_required',
        ),
      );
      return null;
    }

    final workshopIds = state.items
        .map((item) => item.product.workshopId.trim())
        .toSet();

    if (workshopIds.contains('') || workshopIds.length != 1) {
      emit(
        state.copyWith(
          checkoutStatus: CartCheckoutStatus.failure,
          checkoutError: 'cart_products_multiple_workshops',
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
      await refreshWorkshopDeliveryFee();
      final result = await _createCartOrder(
        CartCheckoutRequest(
          products: state.items
              .map(
                (item) => CartCheckoutProduct(
                  inventoryItemId: item.product.id,
                  quantity: item.quantity,
                ),
              )
              .toList(growable: false),
          homeDelivery: state.homeDelivery,
          deliveryDetails: state.homeDelivery
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

      clear();
      return result;
    } catch (error) {
      emit(
        state.copyWith(
          checkoutStatus: CartCheckoutStatus.failure,
          checkoutError: _errorKey(error),
        ),
      );
      return null;
    }
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
    );
  }

  CartState _stateWithItems(List<CartItem> items) {
    if (items.isEmpty) {
      return state.copyWith(
        items: items,
        homeDelivery: false,
        clearCurrentWorkshopDeliveryFee: true,
      );
    }

    return state.copyWith(items: items);
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
