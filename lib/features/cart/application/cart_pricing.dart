class CartPricing {
  const CartPricing._();

  static const double taxRate = 0.13;

  static double subtotal(Iterable<double> lineSubtotals) {
    return _roundCurrency(
      lineSubtotals.fold(0, (total, subtotal) => total + subtotal),
    );
  }

  static double netSubtotal(double taxIncludedTotal) {
    final total = _roundCurrency(taxIncludedTotal);
    return _roundCurrency(total / (1 + taxRate));
  }

  static double includedTaxes(double taxIncludedTotal) {
    final total = _roundCurrency(taxIncludedTotal);
    return _roundCurrency(total - netSubtotal(total));
  }

  /// Returns null when the shipping cost isn't actually known yet -- home
  /// delivery is selected, the workshop's live delivery fee hasn't been
  /// fetched, and no cart item has a captured fee to fall back on either.
  /// Callers must not treat that as "confirmed free": a bare 0 here would
  /// be indistinguishable from a workshop that genuinely charges nothing,
  /// which is exactly what caused "Envío gratis" to flash briefly while
  /// the real fee was still loading.
  static double? shippingCost({
    required bool hasItems,
    required bool homeDelivery,
    required double? currentWorkshopDeliveryFee,
    required Iterable<double?> itemDeliveryFees,
  }) {
    if (!homeDelivery || !hasItems) {
      return 0;
    }

    if (currentWorkshopDeliveryFee != null) {
      return currentWorkshopDeliveryFee;
    }

    for (final fee in itemDeliveryFees) {
      if (fee != null) return fee;
    }

    return null;
  }

  static double _roundCurrency(double value) {
    return (value * 100).roundToDouble() / 100;
  }
}
