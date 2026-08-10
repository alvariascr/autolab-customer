import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/cart_checkout.dart';
import '../models/cart_checkout_models.dart';

abstract interface class ICartCheckoutRemoteDataSource {
  Future<List<CustomerDeliveryAddress>> getDeliveryAddresses();

  Future<CustomerDeliveryAddress> saveDeliveryAddress(
    CustomerDeliveryAddressRequest request, {
    String? addressId,
  });

  Future<CustomerDeliveryAddress> setDefaultDeliveryAddress(String addressId);

  Future<void> deleteDeliveryAddress(String addressId);

  Future<CartCheckoutResult> createOrder(CartCheckoutRequest request);
}

class SupabaseCartCheckoutRemoteDataSource
    implements ICartCheckoutRemoteDataSource {
  const SupabaseCartCheckoutRemoteDataSource(this._client);

  final SupabaseClient _client;

  @override
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
          .map(CustomerDeliveryAddressModel.fromJson)
          .toList(growable: false);
    } on PostgrestException catch (error) {
      throw CartCheckoutException(_cartErrorKey(error.message));
    } on AuthException catch (error) {
      throw CartCheckoutException(_cartErrorKey(error.message));
    }
  }

  @override
  Future<CustomerDeliveryAddress> saveDeliveryAddress(
    CustomerDeliveryAddressRequest request, {
    String? addressId,
  }) async {
    _requireUserId();

    try {
      final response = await _client.rpc(
        'save_customer_delivery_address',
        params: {
          'p_address_id': addressId == null || addressId.trim().isEmpty
              ? null
              : addressId,
          'p_province': request.province.trim(),
          'p_canton': request.canton.trim(),
          'p_district': request.district.trim(),
          'p_exact_address': request.exactAddress.trim(),
          'p_phone': request.phone.trim(),
        },
      );

      return CustomerDeliveryAddressModel.fromJson(
        Map<String, dynamic>.from(response),
      );
    } on PostgrestException catch (error) {
      throw CartCheckoutException(_cartErrorKey(error.message));
    } on AuthException catch (error) {
      throw CartCheckoutException(_cartErrorKey(error.message));
    }
  }

  @override
  Future<CustomerDeliveryAddress> setDefaultDeliveryAddress(
    String addressId,
  ) async {
    _requireUserId();

    try {
      final response = await _client.rpc(
        'set_default_customer_delivery_address',
        params: {'p_address_id': addressId},
      );

      return CustomerDeliveryAddressModel.fromJson(
        Map<String, dynamic>.from(response),
      );
    } on PostgrestException catch (error) {
      throw CartCheckoutException(_cartErrorKey(error.message));
    } on AuthException catch (error) {
      throw CartCheckoutException(_cartErrorKey(error.message));
    }
  }

  @override
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

  @override
  Future<CartCheckoutResult> createOrder(CartCheckoutRequest request) async {
    final Object? response;
    try {
      response = await _client.rpc(
        'create_cart_order',
        params: {
          'p_products': request.products
              .map(
                (product) => {
                  'inventory_item_id': product.inventoryItemId,
                  'inventoryItemId': product.inventoryItemId,
                  'quantity': product.quantity,
                },
              )
              .toList(growable: false),
          'p_home_delivery': request.homeDelivery,
          'p_delivery_details': request.deliveryDetails == null
              ? null
              : CartCheckoutDeliveryDetailsModel.fromEntity(
                  request.deliveryDetails!,
                ).toJson(),
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

    return CartCheckoutResultModel.fromJson(
      Map<String, dynamic>.from(response),
    );
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
