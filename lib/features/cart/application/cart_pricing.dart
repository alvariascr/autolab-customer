class CartPricing {
  const CartPricing._();

  static const double taxRate = 0.13;

  static double subtotal(Iterable<double> lineSubtotals) {
    return lineSubtotals.fold(0, (total, subtotal) => total + subtotal);
  }

  static double taxes(double subtotal) {
    return _roundCurrency(subtotal * taxRate);
  }

  static double shippingCost({
    required bool hasItems,
    required bool homeDelivery,
    required double? currentWorkshopDeliveryFee,
    required Iterable<double> itemDeliveryFees,
  }) {
    if (!homeDelivery || !hasItems) {
      return 0;
    }

    if (currentWorkshopDeliveryFee != null) {
      return currentWorkshopDeliveryFee;
    }

    return itemDeliveryFees.firstWhere((fee) => fee > 0, orElse: () => 0);
  }

  static double _roundCurrency(double value) {
    return (value * 100).roundToDouble() / 100;
  }
}
