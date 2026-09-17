import 'package:flutter/material.dart';

import '../../../../core/theme/autolab_customer.dart';

/// Circular add affordance used on product previews and result cards.
class ProductAddBadge extends StatelessWidget {
  const ProductAddBadge({super.key, this.size = 42, this.iconSize = 31});

  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AutolabCustomer.white,
        shape: BoxShape.circle,
        boxShadow: AutolabCustomer.shadowLevel1,
      ),
      child: Icon(
        Icons.add_rounded,
        size: iconSize,
        color: AutolabCustomer.secondary,
      ),
    );
  }
}
