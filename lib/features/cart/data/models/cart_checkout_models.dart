import '../../domain/entities/cart_checkout.dart';

class CustomerDeliveryAddressModel extends CustomerDeliveryAddress {
  const CustomerDeliveryAddressModel({
    required super.id,
    required super.province,
    required super.canton,
    required super.district,
    required super.exactAddress,
    required super.phone,
    required super.isDefault,
  });

  factory CustomerDeliveryAddressModel.fromJson(Map<String, dynamic> json) {
    return CustomerDeliveryAddressModel(
      id: json['id']?.toString() ?? '',
      province: json['province']?.toString() ?? '',
      canton: json['canton']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      exactAddress: json['exact_address']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      isDefault: json['is_default'] as bool? ?? false,
    );
  }
}

class CartCheckoutDeliveryDetailsModel {
  const CartCheckoutDeliveryDetailsModel({
    required this.province,
    required this.canton,
    required this.district,
    required this.exactAddress,
    required this.phone,
  });

  factory CartCheckoutDeliveryDetailsModel.fromEntity(
    CartCheckoutDeliveryDetails details,
  ) {
    return CartCheckoutDeliveryDetailsModel(
      province: details.province,
      canton: details.canton,
      district: details.district,
      exactAddress: details.exactAddress,
      phone: details.phone,
    );
  }

  final String province;
  final String canton;
  final String district;
  final String exactAddress;
  final String phone;

  Map<String, dynamic> toJson() {
    return {
      'province': province,
      'canton': canton,
      'district': district,
      'exact_address': exactAddress,
      'exactAddress': exactAddress,
      'phone': phone,
    };
  }
}

class CartCheckoutResultModel extends CartCheckoutResult {
  const CartCheckoutResultModel({
    required super.orderId,
    required super.orderNumber,
    required super.totalAmount,
  });

  factory CartCheckoutResultModel.fromJson(Map<String, dynamic> json) {
    return CartCheckoutResultModel(
      orderId: (json['orderId'] ?? json['order_id'])?.toString() ?? '',
      orderNumber:
          (json['orderNumber'] ?? json['order_number'])?.toString() ?? '',
      totalAmount:
          ((json['totalAmount'] ?? json['total_amount']) as num?)?.toDouble() ??
          0,
    );
  }
}
