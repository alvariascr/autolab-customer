import '../../products/domain/entities/product.dart';
import 'cart_state.dart';

class CartItemsService {
  const CartItemsService();

  CartItemsUpdate addProduct(
    CartState state,
    Product product, {
    required int quantity,
  }) {
    if (!_isPhysicalProduct(product) || quantity <= 0) {
      return CartItemsUpdate.unchanged(state.items);
    }

    final items = [...state.items];
    final index = items.indexWhere((item) => item.product.id == product.id);
    final stock = product.currentStock;
    final currentQuantity = index == -1 ? 0 : items[index].quantity;
    final nextQuantity = currentQuantity + quantity;

    if (stock != null && stock >= 0 && nextQuantity > stock) {
      return CartItemsUpdate.unchanged(state.items);
    }

    if (index == -1) {
      items.add(CartItem(product: product, quantity: quantity));
    } else {
      final current = items[index];
      items[index] = current.copyWith(product: product, quantity: nextQuantity);
    }

    return CartItemsUpdate(
      items: items,
      wasChanged: true,
      startedNewCart: state.items.isEmpty,
    );
  }

  CartItemsUpdate updateQuantity(
    CartState state,
    String productId,
    int Function(int quantity) update,
  ) {
    var wasChanged = false;
    final items = state.items
        .map((item) {
          if (item.product.id != productId) {
            return item;
          }

          final nextQuantity = update(item.quantity);
          final stock = item.product.currentStock;
          if (stock != null && stock >= 0 && nextQuantity > stock) {
            return item;
          }

          wasChanged = nextQuantity != item.quantity;
          return item.copyWith(quantity: nextQuantity);
        })
        .where((item) => item.quantity > 0)
        .toList(growable: false);

    return CartItemsUpdate(
      items: items,
      wasChanged: wasChanged,
      startedNewCart: false,
    );
  }

  List<CartItem> removeProduct(CartState state, String productId) {
    return state.items
        .where((item) => item.product.id != productId)
        .toList(growable: false);
  }

  bool _isPhysicalProduct(Product product) {
    return product.itemType.trim().toLowerCase() != 'service';
  }
}

class CartItemsUpdate {
  const CartItemsUpdate({
    required this.items,
    required this.wasChanged,
    required this.startedNewCart,
  });

  CartItemsUpdate.unchanged(List<CartItem> items)
    : this(items: items, wasChanged: false, startedNewCart: false);

  final List<CartItem> items;
  final bool wasChanged;
  final bool startedNewCart;
}
