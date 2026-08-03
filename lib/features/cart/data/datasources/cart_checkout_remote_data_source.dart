import 'package:supabase_flutter/supabase_flutter.dart';

class CartCheckoutRemoteDataSource {
  const CartCheckoutRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<CustomerDeliveryAddress>> getDeliveryAddresses() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.trim().isEmpty) {
      return const [];
    }

    final response = await _client
        .from('customer_delivery_addresses')
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .order('is_default', ascending: false);

    return response
        .whereType<Map<String, dynamic>>()
        .map(CustomerDeliveryAddress.fromJson)
        .toList(growable: false);
  }

  Future<CustomerDeliveryAddress> saveDeliveryAddress(
    CustomerDeliveryAddressRequest request, {
    String? addressId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.trim().isEmpty) {
      throw const CartCheckoutException('cart_auth_required');
    }

    await _client
        .from('customer_delivery_addresses')
        .update({'is_default': false})
        .eq('user_id', userId);

    final payload = {
      'user_id': userId,
      'province': request.province.trim(),
      'canton': request.canton.trim(),
      'district': request.district.trim(),
      'exact_address': request.exactAddress.trim(),
      'phone': request.phone.trim(),
      'is_default': true,
      'is_active': true,
    };

    final response = addressId == null || addressId.trim().isEmpty
        ? await _client
              .from('customer_delivery_addresses')
              .insert(payload)
              .select()
              .single()
        : await _client
              .from('customer_delivery_addresses')
              .update(payload)
              .eq('id', addressId)
              .eq('user_id', userId)
              .select()
              .single();

    return CustomerDeliveryAddress.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  Future<CustomerDeliveryAddress> setDefaultDeliveryAddress(
    String addressId,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.trim().isEmpty) {
      throw const CartCheckoutException('cart_auth_required');
    }

    await _client
        .from('customer_delivery_addresses')
        .update({'is_default': false})
        .eq('user_id', userId);

    final response = await _client
        .from('customer_delivery_addresses')
        .update({'is_default': true})
        .eq('id', addressId)
        .eq('user_id', userId)
        .select()
        .single();

    return CustomerDeliveryAddress.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  Future<void> deleteDeliveryAddress(String addressId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.trim().isEmpty) {
      throw const CartCheckoutException('cart_auth_required');
    }

    await _client
        .from('customer_delivery_addresses')
        .update({'is_active': false, 'is_default': false})
        .eq('id', addressId)
        .eq('user_id', userId);
  }

  Future<CartCheckoutResult> createOrder(CartCheckoutRequest request) async {
    final response = await _client.rpc(
      'create_cart_order',
      params: {
        'p_products': request.products
            .map(
              (product) => {
                'inventoryItemId': product.inventoryItemId,
                'quantity': product.quantity,
              },
            )
            .toList(growable: false),
        'p_home_delivery': request.homeDelivery,
        'p_delivery_details': request.deliveryDetails?.toJson(),
      },
    );

    return CartCheckoutResult.fromJson(Map<String, dynamic>.from(response));
  }
}

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

  factory CustomerDeliveryAddress.fromJson(Map<String, dynamic> json) {
    return CustomerDeliveryAddress(
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

  Map<String, dynamic> toJson() {
    return {
      'province': province,
      'canton': canton,
      'district': district,
      'exactAddress': exactAddress,
      'phone': phone,
    };
  }
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

  factory CartCheckoutResult.fromJson(Map<String, dynamic> json) {
    return CartCheckoutResult(
      orderId: json['orderId']?.toString() ?? '',
      orderNumber: json['orderNumber']?.toString() ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
    );
  }
}
