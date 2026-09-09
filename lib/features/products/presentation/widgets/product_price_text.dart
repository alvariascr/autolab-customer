import 'package:flutter/material.dart';

import '../../../../core/theme/autolab_customer.dart';
import '../../../../core/utils/currency_format.dart';

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
            color: AutolabCustomer.customerTextColor(context),
            fontWeight: FontWeight.w800,
          ),
    );
  }
}

String formatProductPrice(double? price) {
  if (price == null) {
    return 'Consultar precio';
  }

  return formatColones(price);
}
