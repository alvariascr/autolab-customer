class CartPricing {
  const CartPricing._();

  static const double taxRate = 0.13;

  static double subtotal(Iterable<double> lineSubtotals) {
    return lineSubtotals.fold(0, (total, subtotal) => total + subtotal);
  }

  static double netSubtotal(double taxIncludedTotal) {
    return _roundCurrency(taxIncludedTotal / (1 + taxRate));
  }

  static double includedTaxes(double taxIncludedTotal) {
    return _roundCurrency(taxIncludedTotal - netSubtotal(taxIncludedTotal));
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
