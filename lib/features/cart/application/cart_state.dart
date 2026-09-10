import 'package:equatable/equatable.dart';

import '../../products/domain/entities/product.dart';
import '../domain/entities/cart_checkout.dart';
import 'cart_pricing.dart';

class CartState extends Equatable {
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
    this.currentWorkshopDeliveryFeeWorkshopId,
    this.deliveryAddressesError,
    this.checkoutStatus = CartCheckoutStatus.initial,
    this.checkoutError,
    this.pendingCheckoutResult,
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
  // Which workshop currentWorkshopDeliveryFee was fetched for. Needed
  // because refreshWorkshopDeliveryFee() is async: forWorkshop() can be
  // called (via a rebuild) for a different workshop than the one whose fee
  // is currently cached, in the brief window before that fetch resolves --
  // without this, forWorkshop() would have no way to tell whether the
  // cached fee actually belongs to the workshop being requested.
  final String? currentWorkshopDeliveryFeeWorkshopId;
  final String? deliveryAddressesError;
  final CartCheckoutStatus checkoutStatus;
  final String? checkoutError;
  final CartCheckoutResult? pendingCheckoutResult;

  int get totalQuantity {
    return items.fold(0, (total, item) => total + item.quantity);
  }

  double get productsTotal {
    return CartPricing.subtotal(items.map((item) => item.lineSubtotal));
  }

  double get subtotal => CartPricing.netSubtotal(productsTotal);

  double get taxes => CartPricing.includedTaxes(productsTotal);

  double? get _rawShippingCost {
    return CartPricing.shippingCost(
      hasItems: items.isNotEmpty,
      homeDelivery: homeDelivery,
      currentWorkshopDeliveryFee: currentWorkshopDeliveryFee,
      itemDeliveryFees: items.map((item) => item.product.workshopDeliveryFee),
    );
  }

  double get shippingCost => _rawShippingCost ?? 0;

  /// Whether [shippingCost] reflects an actually-known fee (the workshop's
  /// live delivery fee, or one captured on a cart item) rather than the
  /// same 0 used as a placeholder while neither is available yet. UI that
  /// shows a "free shipping" badge must check this first -- otherwise it
  /// can't tell a workshop that genuinely charges nothing apart from a fee
  /// that just hasn't loaded.
  bool get isShippingCostConfirmed => _rawShippingCost != null;

  double get total => productsTotal + shippingCost;

  String? get singleWorkshopId {
    final workshopIds = items
        .map((item) => item.product.workshopId.trim())
        .where((workshopId) => workshopId.isNotEmpty)
        .toSet();

    return workshopIds.length == 1 ? workshopIds.single : null;
  }

  List<CartWorkshopCart> get workshopCarts => _buildWorkshopCarts();

  List<CartWorkshopCart> _buildWorkshopCarts() {
    final groupedItems = <String, List<CartItem>>{};

    for (final item in items) {
      final workshopId = item.product.workshopId.trim();
      if (workshopId.isEmpty) {
        continue;
      }

      groupedItems.putIfAbsent(workshopId, () => []).add(item);
    }

    return groupedItems.entries
        .map(
          (entry) =>
              CartWorkshopCart(workshopId: entry.key, items: entry.value),
        )
        .toList(growable: false);
  }

  CartState forWorkshop(String workshopId) {
    final trimmedWorkshopId = workshopId.trim();

    return CartState(
      items: items
          .where((item) => item.product.workshopId.trim() == trimmedWorkshopId)
          .toList(growable: false),
      homeDelivery: homeDelivery,
      deliveryAddress: deliveryAddress,
      deliveryProvince: deliveryProvince,
      deliveryCanton: deliveryCanton,
      deliveryDistrict: deliveryDistrict,
      deliveryExactAddress: deliveryExactAddress,
      deliveryPhoneNumber: deliveryPhoneNumber,
      selectedDeliveryAddressId: selectedDeliveryAddressId,
      deliveryAddresses: deliveryAddresses,
      // Only forward the cached fee if it actually belongs to this
      // workshop -- otherwise the checkout summary could briefly show one
      // workshop's fee mislabeled as another's (see the field's doc
      // comment). Without this check at all, the summary previously always
      // fell back to the stale per-item delivery fee captured when the
      // product was added, silently ignoring whatever
      // refreshWorkshopDeliveryFee() just fetched.
      currentWorkshopDeliveryFee:
          currentWorkshopDeliveryFeeWorkshopId == trimmedWorkshopId
          ? currentWorkshopDeliveryFee
          : null,
      currentWorkshopDeliveryFeeWorkshopId:
          currentWorkshopDeliveryFeeWorkshopId == trimmedWorkshopId
          ? currentWorkshopDeliveryFeeWorkshopId
          : null,
      deliveryAddressesError: deliveryAddressesError,
      checkoutStatus: checkoutStatus,
      checkoutError: checkoutError,
      pendingCheckoutResult: pendingCheckoutResult,
    );
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
    String? currentWorkshopDeliveryFeeWorkshopId,
    String? deliveryAddressesError,
    CartCheckoutStatus? checkoutStatus,
    String? checkoutError,
    CartCheckoutResult? pendingCheckoutResult,
    bool clearDeliveryDetails = false,
    bool clearCurrentWorkshopDeliveryFee = false,
    bool clearDeliveryAddressesError = false,
    bool clearCheckoutError = false,
    bool clearPendingCheckoutResult = false,
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
      currentWorkshopDeliveryFeeWorkshopId: clearCurrentWorkshopDeliveryFee
          ? null
          : currentWorkshopDeliveryFeeWorkshopId ??
                this.currentWorkshopDeliveryFeeWorkshopId,
      deliveryAddressesError: clearDeliveryAddressesError
          ? null
          : deliveryAddressesError ?? this.deliveryAddressesError,
      checkoutStatus: checkoutStatus ?? this.checkoutStatus,
      checkoutError: clearCheckoutError
          ? null
          : checkoutError ?? this.checkoutError,
      pendingCheckoutResult: clearPendingCheckoutResult
          ? null
          : pendingCheckoutResult ?? this.pendingCheckoutResult,
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
      // Persisted so a checkout that succeeded on the server but got
      // interrupted before the cart could be cleared (app killed while
      // Laropay's external browser has focus, etc.) is remembered across a
      // relaunch -- otherwise a retry with the same untouched cart creates a
      // second real order for the same products.
      if (pendingCheckoutResult != null)
        'pendingCheckoutResult': pendingCheckoutResult!.toJson(),
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
      pendingCheckoutResult: CartCheckoutResult.fromJson(
        json['pendingCheckoutResult'] is Map<String, dynamic>
            ? json['pendingCheckoutResult'] as Map<String, dynamic>
            : null,
      ),
    );
  }

  @override
  List<Object?> get props => [
    items,
    homeDelivery,
    deliveryAddress,
    deliveryProvince,
    deliveryCanton,
    deliveryDistrict,
    deliveryExactAddress,
    deliveryPhoneNumber,
    selectedDeliveryAddressId,
    deliveryAddresses,
    currentWorkshopDeliveryFee,
    currentWorkshopDeliveryFeeWorkshopId,
    deliveryAddressesError,
    checkoutStatus,
    checkoutError,
    pendingCheckoutResult,
  ];
}

enum CartCheckoutStatus {
  initial,
  loading,
  failure;

  bool get isLoading => this == CartCheckoutStatus.loading;
}

class CartItem extends Equatable {
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

  @override
  List<Object?> get props => [product, quantity];
}

class CartWorkshopCart extends Equatable {
  const CartWorkshopCart({required this.workshopId, required this.items})
    : assert(items.length > 0);

  final String workshopId;
  final List<CartItem> items;

  Product get representativeProduct {
    return items
        .map((item) => item.product)
        .firstWhere(_hasWorkshopMetadata, orElse: () => items.first.product);
  }

  String get workshopName => representativeProduct.workshopName.trim();

  String get workshopAvatarUrl =>
      representativeProduct.workshopAvatarUrl.trim();

  bool _hasWorkshopMetadata(Product product) {
    return product.workshopName.trim().isNotEmpty ||
        product.workshopAvatarUrl.trim().isNotEmpty;
  }

  int get totalQuantity {
    return items.fold(0, (total, item) => total + item.quantity);
  }

  double get productsTotal {
    return CartPricing.subtotal(items.map((item) => item.lineSubtotal));
  }

  @override
  List<Object?> get props => [workshopId, items];
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
