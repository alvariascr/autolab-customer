import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';

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
          AppTextStyles.subtitle.copyWith(
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
