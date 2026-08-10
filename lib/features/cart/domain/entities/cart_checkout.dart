import 'package:equatable/equatable.dart';

class CustomerDeliveryAddress extends Equatable {
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

  @override
  List<Object?> get props => [
    id,
    province,
    canton,
    district,
    exactAddress,
    phone,
    isDefault,
  ];
}

class CustomerDeliveryAddressRequest extends Equatable {
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

  @override
  List<Object?> get props => [province, canton, district, exactAddress, phone];
}

class CartCheckoutException extends Equatable implements Exception {
  const CartCheckoutException(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}

class CartCheckoutRequest extends Equatable {
  const CartCheckoutRequest({
    required this.products,
    required this.homeDelivery,
    this.deliveryDetails,
  });

  final List<CartCheckoutProduct> products;
  final bool homeDelivery;
  final CartCheckoutDeliveryDetails? deliveryDetails;

  @override
  List<Object?> get props => [products, homeDelivery, deliveryDetails];
}

class CartCheckoutProduct extends Equatable {
  const CartCheckoutProduct({
    required this.inventoryItemId,
    required this.quantity,
  });

  final String inventoryItemId;
  final int quantity;

  @override
  List<Object?> get props => [inventoryItemId, quantity];
}

class CartCheckoutDeliveryDetails extends Equatable {
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

  @override
  List<Object?> get props => [province, canton, district, exactAddress, phone];
}

class CartCheckoutResult extends Equatable {
  const CartCheckoutResult({
    required this.orderId,
    required this.orderNumber,
    required this.totalAmount,
  });

  final String orderId;
  final String orderNumber;
  final double totalAmount;

  @override
  List<Object?> get props => [orderId, orderNumber, totalAmount];
}
