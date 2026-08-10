class CustomerDeliveryAddress {
  const CustomerDeliveryAddress({
    required this.id,
    required this.province,
    required this.canton,
    required this.district,
    required this.exactAddress,
    required this.phone,
    required this.isDefault,
  });

  final String id;
  final String province;
  final String canton;
  final String district;
  final String exactAddress;
  final String phone;
  final bool isDefault;

  String get summary {
    return [
      province,
      canton,
      district,
      exactAddress,
    ].where((part) => part.trim().isNotEmpty).join(', ');
  }

  String get shortLabel {
    final parts = [
      district,
      canton,
    ].where((part) => part.trim().isNotEmpty).toList(growable: false);

    return parts.isEmpty ? exactAddress : parts.join(', ');
  }
}

class CustomerDeliveryAddressRequest {
  const CustomerDeliveryAddressRequest({
    required this.province,
    required this.canton,
    required this.district,
    required this.exactAddress,
    required this.phone,
  });

  final String province;
  final String canton;
  final String district;
  final String exactAddress;
  final String phone;
}

class CartCheckoutException implements Exception {
  const CartCheckoutException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CartCheckoutRequest {
  const CartCheckoutRequest({
    required this.products,
    required this.homeDelivery,
    this.deliveryDetails,
  });

  final List<CartCheckoutProduct> products;
  final bool homeDelivery;
  final CartCheckoutDeliveryDetails? deliveryDetails;
}

class CartCheckoutProduct {
  const CartCheckoutProduct({
    required this.inventoryItemId,
    required this.quantity,
  });

  final String inventoryItemId;
  final int quantity;
}

class CartCheckoutDeliveryDetails {
  const CartCheckoutDeliveryDetails({
    required this.province,
    required this.canton,
    required this.district,
    required this.exactAddress,
    required this.phone,
  });

  final String province;
  final String canton;
  final String district;
  final String exactAddress;
  final String phone;
}

class CartCheckoutResult {
  const CartCheckoutResult({
    required this.orderId,
    required this.orderNumber,
    required this.totalAmount,
  });

  final String orderId;
  final String orderNumber;
  final double totalAmount;
}
