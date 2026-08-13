import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'cart_state.dart';

class CartPersistence {
  const CartPersistence();

  static const String storageKey = 'customer_cart';
  static Future<void> _pendingWrite = Future.value();
  static final _cartChangesController = StreamController<CartState>.broadcast();

  Stream<CartState> watch() => _cartChangesController.stream;

  Future<CartState?> load() async {
    await waitForPendingWrites();
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
    final write = waitForPendingWrites().then((_) async {
      try {
        final preferences = await SharedPreferences.getInstance();
        await preferences.setString(storageKey, jsonEncode(cart.toJson()));
      } catch (_) {
        // La persistencia local es best-effort y no debe romper el flujo.
      }
    });

    _pendingWrite = write;
    await write;
    _cartChangesController.add(cart);
  }

  Future<void> clear() async {
    final write = waitForPendingWrites().then((_) async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(storageKey);
    });

    _pendingWrite = write;
    await write;
    _cartChangesController.add(const CartState());
  }

  Future<void> waitForPendingWrites() {
    return _pendingWrite.catchError((_) {
      // Mantenga viva la cola aunque una escritura previa falle.
    });
  }
}
