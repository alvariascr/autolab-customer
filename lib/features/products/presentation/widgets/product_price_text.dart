import 'package:flutter/material.dart';

import '../../../../core/theme/autolab_customer.dart';

class ProductPriceText extends StatelessWidget {
  const ProductPriceText({super.key, required this.price, this.style});

  final double? price;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      formatProductPrice(price),
      style:
          style ??
          AutolabCustomer.bodyLarge.copyWith(
            color: const Color(0xFF181411),
            fontWeight: FontWeight.w800,
          ),
    );
  }
}

String formatProductPrice(double? price) {
  if (price == null) {
    return 'Consultar precio';
  }

  return '\u20A1${price.toStringAsFixed(0)}';
}
