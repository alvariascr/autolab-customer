import '../../products/domain/entities/product.dart';
import '../domain/entities/cart_checkout.dart';
import 'cart_pricing.dart';

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
    return CartPricing.subtotal(items.map((item) => item.lineSubtotal));
  }

  double get taxes => CartPricing.taxes(subtotal);

  double get shippingCost {
    return CartPricing.shippingCost(
      hasItems: items.isNotEmpty,
      homeDelivery: homeDelivery,
      currentWorkshopDeliveryFee: currentWorkshopDeliveryFee,
      itemDeliveryFees: items.map((item) => item.product.workshopDeliveryFee),
    );
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
