import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/cart_checkout.dart';

class CartCheckoutRemoteDataSource {
  const CartCheckoutRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<CustomerDeliveryAddress>> getDeliveryAddresses() async {
    final userId = _requireUserId();

    try {
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
    } on PostgrestException catch (error) {
      throw CartCheckoutException(_cartErrorKey(error.message));
    } on AuthException catch (error) {
      throw CartCheckoutException(_cartErrorKey(error.message));
    }
  }

  Future<CustomerDeliveryAddress> saveDeliveryAddress(
    CustomerDeliveryAddressRequest request, {
    String? addressId,
  }) async {
    final userId = _requireUserId();

    try {
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
    } on PostgrestException catch (error) {
      throw CartCheckoutException(_cartErrorKey(error.message));
    } on AuthException catch (error) {
      throw CartCheckoutException(_cartErrorKey(error.message));
    }
  }

  Future<CustomerDeliveryAddress> setDefaultDeliveryAddress(
    String addressId,
  ) async {
    final userId = _requireUserId();

    try {
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
    } on PostgrestException catch (error) {
      throw CartCheckoutException(_cartErrorKey(error.message));
    } on AuthException catch (error) {
      throw CartCheckoutException(_cartErrorKey(error.message));
    }
  }

  Future<void> deleteDeliveryAddress(String addressId) async {
    final userId = _requireUserId();

    try {
      await _client
          .from('customer_delivery_addresses')
          .update({'is_active': false, 'is_default': false})
          .eq('id', addressId)
          .eq('user_id', userId);
    } on PostgrestException catch (error) {
      throw CartCheckoutException(_cartErrorKey(error.message));
    } on AuthException catch (error) {
      throw CartCheckoutException(_cartErrorKey(error.message));
    }
  }

  Future<double> getWorkshopDeliveryFee(String workshopId) async {
    try {
      final response = await _client
          .from('workshops')
          .select('delivery_fee')
          .eq('id', workshopId)
          .single();

      return (response['delivery_fee'] as num?)?.toDouble() ?? 0;
    } on PostgrestException catch (error) {
      throw CartCheckoutException(_cartErrorKey(error.message));
    } on AuthException catch (error) {
      throw CartCheckoutException(_cartErrorKey(error.message));
    }
  }

  Future<CartCheckoutResult> createOrder(CartCheckoutRequest request) async {
    final Object? response;
    try {
      response = await _client.rpc(
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
    } on PostgrestException catch (error) {
      throw CartCheckoutException(_cartErrorKey(error.message));
    } on AuthException catch (error) {
      throw CartCheckoutException(_cartErrorKey(error.message));
    }

    if (response is! Map) {
      throw const CartCheckoutException('cart_checkout_failed');
    }

    return CartCheckoutResult.fromJson(Map<String, dynamic>.from(response));
  }

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.trim().isEmpty) {
      throw const CartCheckoutException('cart_auth_required');
    }

    return userId;
  }
}

String _cartErrorKey(String message) {
  final match = RegExp(r'cart_[a-z0-9_]+').firstMatch(message);
  return match?.group(0) ?? 'cart_unexpected_error';
}
