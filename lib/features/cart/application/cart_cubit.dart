import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../products/domain/entities/product.dart';
import '../domain/entities/cart_checkout.dart';
import '../domain/usecases/create_cart_order.dart';
import '../domain/usecases/delete_delivery_address.dart';
import '../domain/usecases/get_workshop_delivery_fee.dart';
import '../domain/usecases/load_delivery_addresses.dart';
import '../domain/usecases/save_delivery_address.dart';
import '../domain/usecases/set_default_delivery_address.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit({
    required LoadDeliveryAddresses loadDeliveryAddresses,
    required SaveDeliveryAddress saveDeliveryAddress,
    required SetDefaultDeliveryAddress setDefaultDeliveryAddress,
    required DeleteDeliveryAddress deleteDeliveryAddress,
    required GetWorkshopDeliveryFee getWorkshopDeliveryFee,
    required CreateCartOrder createCartOrder,
  }) : _loadDeliveryAddresses = loadDeliveryAddresses,
       _saveDeliveryAddress = saveDeliveryAddress,
       _setDefaultDeliveryAddress = setDefaultDeliveryAddress,
       _deleteDeliveryAddress = deleteDeliveryAddress,
       _getWorkshopDeliveryFee = getWorkshopDeliveryFee,
       _createCartOrder = createCartOrder,
       super(const CartState()) {
    unawaited(_initializeCart());
  }

  final LoadDeliveryAddresses _loadDeliveryAddresses;
  final SaveDeliveryAddress _saveDeliveryAddress;
  final SetDefaultDeliveryAddress _setDefaultDeliveryAddress;
  final DeleteDeliveryAddress _deleteDeliveryAddress;
  final GetWorkshopDeliveryFee _getWorkshopDeliveryFee;
  final CreateCartOrder _createCartOrder;
  var _sessionVersion = 0;
  var _cartMutationVersion = 0;

  static const double taxRate = 0.13;
  static const String _storageKey = 'customer_cart';

  void addProduct(Product product, {int quantity = 1}) {
    if (!_isPhysicalProduct(product) || quantity <= 0) {
      return;
    }

    final items = [...state.items];
    final index = items.indexWhere((item) => item.product.id == product.id);
    final isStartingNewCart = state.items.isEmpty;

    if (index == -1) {
      items.add(CartItem(product: product, quantity: quantity));
    } else {
      final current = items[index];
      items[index] = current.copyWith(
        product: product,
        quantity: current.quantity + quantity,
      );
    }

    _emitAndSave(
      state.copyWith(
        items: items,
        homeDelivery: isStartingNewCart ? false : null,
      ),
    );
  }

  void increaseQuantity(String productId) {
    _updateQuantity(productId, (quantity) => quantity + 1);
  }

  void decreaseQuantity(String productId) {
    _updateQuantity(productId, (quantity) => quantity - 1);
  }

  void removeProduct(String productId) {
    final items = state.items
        .where((item) => item.product.id != productId)
        .toList(growable: false);

    _emitAndSave(_stateWithItems(items));
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

    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
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

  Future<void> deleteDeliveryAddress(String addressId) async {
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
    } catch (error) {
      emit(state.copyWith(deliveryAddressesError: _errorKey(error)));
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

  void _updateQuantity(String productId, int Function(int quantity) update) {
    final items = state.items
        .map((item) {
          if (item.product.id != productId) {
            return item;
          }

          return item.copyWith(quantity: update(item.quantity));
        })
        .where((item) => item.quantity > 0)
        .toList(growable: false);

    _emitAndSave(_stateWithItems(items));
  }

  bool _isPhysicalProduct(Product product) {
    return product.itemType.trim().toLowerCase() != 'service';
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
    final preferences = await SharedPreferences.getInstance();
    final rawCart = preferences.getString(_storageKey);
    if (rawCart == null || rawCart.trim().isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(rawCart) as Map<String, dynamic>;
      if (sessionVersion != _sessionVersion ||
          mutationVersion != _cartMutationVersion) {
        return;
      }
      emit(CartState.fromJson(decoded));
    } on FormatException {
      await preferences.remove(_storageKey);
    } on TypeError {
      await preferences.remove(_storageKey);
    }
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
    unawaited(_saveCart(nextState));
  }

  Future<void> _saveCart(CartState cart) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_storageKey, jsonEncode(cart.toJson()));
    } catch (_) {
      // La persistencia local es best-effort y no debe romper el flujo.
    }
  }
}

class CartState {
  const CartState({
    this.items = const [],
    this.homeDelivery = false,
    this.deliveryAddress = '',
    this.deliveryProvince = '',
    this.deliveryCanton = '',
    this.deliveryDistrict = '',
    this.deliveryExactAddress = '',
    this.deliveryPhoneNumber = '',
    this.selectedDeliveryAddressId = '',
    this.deliveryAddresses = const [],
    this.currentWorkshopDeliveryFee,
    this.deliveryAddressesError,
    this.checkoutStatus = CartCheckoutStatus.initial,
    this.checkoutError,
  });

  final List<CartItem> items;
  final bool homeDelivery;
  final String deliveryAddress;
  final String deliveryProvince;
  final String deliveryCanton;
  final String deliveryDistrict;
  final String deliveryExactAddress;
  final String deliveryPhoneNumber;
  final String selectedDeliveryAddressId;
  final List<CustomerDeliveryAddress> deliveryAddresses;
  final double? currentWorkshopDeliveryFee;
  final String? deliveryAddressesError;
  final CartCheckoutStatus checkoutStatus;
  final String? checkoutError;

  int get totalQuantity {
    return items.fold(0, (total, item) => total + item.quantity);
  }

  double get subtotal {
    return items.fold(0, (total, item) => total + item.lineSubtotal);
  }

  double get taxes => subtotal * CartCubit.taxRate;

  double get shippingCost {
    if (!homeDelivery || items.isEmpty) {
      return 0;
    }

    final currentFee = currentWorkshopDeliveryFee;
    if (currentFee != null) {
      return currentFee;
    }

    return items
        .map((item) => item.product.workshopDeliveryFee)
        .firstWhere((fee) => fee > 0, orElse: () => 0);
  }

  double get total => subtotal + taxes + shippingCost;

  String? get singleWorkshopId {
    final workshopIds = items
        .map((item) => item.product.workshopId.trim())
        .where((workshopId) => workshopId.isNotEmpty)
        .toSet();

    return workshopIds.length == 1 ? workshopIds.single : null;
  }

  bool get hasCompleteDeliveryDetails {
    return deliveryProvince.trim().isNotEmpty &&
        deliveryCanton.trim().isNotEmpty &&
        deliveryDistrict.trim().isNotEmpty &&
        deliveryExactAddress.trim().isNotEmpty &&
        deliveryPhoneNumber.trim().isNotEmpty;
  }

  String get deliverySummary {
    return [
      deliveryProvince,
      deliveryCanton,
      deliveryDistrict,
      deliveryExactAddress,
    ].where((part) => part.trim().isNotEmpty).join(', ');
  }

  CartState copyWith({
    List<CartItem>? items,
    bool? homeDelivery,
    String? deliveryAddress,
    String? deliveryProvince,
    String? deliveryCanton,
    String? deliveryDistrict,
    String? deliveryExactAddress,
    String? deliveryPhoneNumber,
    String? selectedDeliveryAddressId,
    List<CustomerDeliveryAddress>? deliveryAddresses,
    double? currentWorkshopDeliveryFee,
    String? deliveryAddressesError,
    CartCheckoutStatus? checkoutStatus,
    String? checkoutError,
    bool clearDeliveryDetails = false,
    bool clearCurrentWorkshopDeliveryFee = false,
    bool clearDeliveryAddressesError = false,
    bool clearCheckoutError = false,
  }) {
    return CartState(
      items: items ?? this.items,
      homeDelivery: homeDelivery ?? this.homeDelivery,
      deliveryAddress: clearDeliveryDetails
          ? ''
          : deliveryAddress ?? this.deliveryAddress,
      deliveryProvince: clearDeliveryDetails
          ? ''
          : deliveryProvince ?? this.deliveryProvince,
      deliveryCanton: clearDeliveryDetails
          ? ''
          : deliveryCanton ?? this.deliveryCanton,
      deliveryDistrict: clearDeliveryDetails
          ? ''
          : deliveryDistrict ?? this.deliveryDistrict,
      deliveryExactAddress: clearDeliveryDetails
          ? ''
          : deliveryExactAddress ?? this.deliveryExactAddress,
      deliveryPhoneNumber: clearDeliveryDetails
          ? ''
          : deliveryPhoneNumber ?? this.deliveryPhoneNumber,
      selectedDeliveryAddressId: clearDeliveryDetails
          ? ''
          : selectedDeliveryAddressId ?? this.selectedDeliveryAddressId,
      deliveryAddresses: deliveryAddresses ?? this.deliveryAddresses,
      currentWorkshopDeliveryFee: clearCurrentWorkshopDeliveryFee
          ? null
          : currentWorkshopDeliveryFee ?? this.currentWorkshopDeliveryFee,
      deliveryAddressesError: clearDeliveryAddressesError
          ? null
          : deliveryAddressesError ?? this.deliveryAddressesError,
      checkoutStatus: checkoutStatus ?? this.checkoutStatus,
      checkoutError: clearCheckoutError
          ? null
          : checkoutError ?? this.checkoutError,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(growable: false),
      'homeDelivery': homeDelivery,
      'deliveryAddress': deliveryAddress,
      'deliveryProvince': deliveryProvince,
      'deliveryCanton': deliveryCanton,
      'deliveryDistrict': deliveryDistrict,
      'deliveryExactAddress': deliveryExactAddress,
      'deliveryPhoneNumber': deliveryPhoneNumber,
      'selectedDeliveryAddressId': selectedDeliveryAddressId,
    };
  }

  factory CartState.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];

    return CartState(
      items: rawItems is List
          ? rawItems
                .whereType<Map<String, dynamic>>()
                .map(CartItem.fromJson)
                .where((item) => item.quantity > 0)
                .toList(growable: false)
          : const [],
      homeDelivery: json['homeDelivery'] as bool? ?? false,
      deliveryAddress: json['deliveryAddress'] as String? ?? '',
      deliveryProvince: json['deliveryProvince'] as String? ?? '',
      deliveryCanton: json['deliveryCanton'] as String? ?? '',
      deliveryDistrict: json['deliveryDistrict'] as String? ?? '',
      deliveryExactAddress:
          json['deliveryExactAddress'] as String? ??
          json['deliveryAddress'] as String? ??
          '',
      deliveryPhoneNumber: json['deliveryPhoneNumber'] as String? ?? '',
      selectedDeliveryAddressId:
          json['selectedDeliveryAddressId'] as String? ?? '',
    );
  }
}

enum CartCheckoutStatus {
  initial,
  loading,
  failure;

  bool get isLoading => this == CartCheckoutStatus.loading;
}

class CartItem {
  const CartItem({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  double get unitPrice => product.sellingPrice ?? 0;

  double get lineSubtotal => unitPrice * quantity;

  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() {
    return {'product': product.toCartJson(), 'quantity': quantity};
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: _productFromCartJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] as int? ?? 1,
    );
  }
}

extension _ProductCartJson on Product {
  Map<String, dynamic> toCartJson() {
    return {
      'id': id,
      'workshopId': workshopId,
      'name': name,
      'description': description,
      'primaryImageUrl': primaryImageUrl,
      'sellingPrice': sellingPrice,
      'currentStock': currentStock,
      'minimumStockAlert': minimumStockAlert,
      'itemType': itemType,
      'status': status,
      'requiresAppointment': requiresAppointment,
      'isSchedulable': isSchedulable,
      'estimatedDurationHours': estimatedDurationHours,
      'skuNumber': skuNumber,
      'barcode': barcode,
      'categoryName': categoryName,
      'brandName': brandName,
      'providerName': providerName,
      'workshopName': workshopName,
      'workshopAvatarUrl': workshopAvatarUrl,
      'workshopDeliveryFee': workshopDeliveryFee,
    };
  }
}

Product _productFromCartJson(Map<String, dynamic> json) {
  return Product(
    id: json['id'] as String? ?? '',
    workshopId: json['workshopId'] as String? ?? '',
    name: json['name'] as String? ?? '',
    description: json['description'] as String? ?? '',
    primaryImageUrl: json['primaryImageUrl'] as String? ?? '',
    sellingPrice: (json['sellingPrice'] as num?)?.toDouble(),
    currentStock: json['currentStock'] as int?,
    minimumStockAlert: json['minimumStockAlert'] as int?,
    itemType: json['itemType'] as String? ?? 'product',
    status: json['status'] as String? ?? '',
    requiresAppointment: json['requiresAppointment'] as bool? ?? false,
    isSchedulable: json['isSchedulable'] as bool? ?? false,
    estimatedDurationHours: (json['estimatedDurationHours'] as num?)
        ?.toDouble(),
    skuNumber: json['skuNumber'] as String? ?? '',
    barcode: json['barcode'] as String? ?? '',
    categoryName: json['categoryName'] as String? ?? '',
    brandName: json['brandName'] as String? ?? '',
    providerName: json['providerName'] as String? ?? '',
    workshopName: json['workshopName'] as String? ?? '',
    workshopAvatarUrl: json['workshopAvatarUrl'] as String? ?? '',
    workshopDeliveryFee: (json['workshopDeliveryFee'] as num?)?.toDouble() ?? 0,
  );
}
