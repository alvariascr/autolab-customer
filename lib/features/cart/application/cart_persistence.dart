import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'cart_state.dart';

class CartPersistence {
  const CartPersistence();

  static const String storageKey = 'customer_cart';

  Future<CartState?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final rawCart = preferences.getString(storageKey);
    if (rawCart == null || rawCart.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawCart) as Map<String, dynamic>;
      return CartState.fromJson(decoded);
    } on FormatException {
      await preferences.remove(storageKey);
      return null;
    } on TypeError {
      await preferences.remove(storageKey);
      return null;
    }
  }

  Future<void> save(CartState cart) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(storageKey, jsonEncode(cart.toJson()));
    } catch (_) {
      // La persistencia local es best-effort y no debe romper el flujo.
    }
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(storageKey);
  }
}
