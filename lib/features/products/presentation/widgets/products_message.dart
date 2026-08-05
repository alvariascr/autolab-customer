import 'package:flutter/material.dart';

import '../../../../core/theme/autolab_customer.dart';

class ProductsMessage extends StatelessWidget {
  const ProductsMessage({
    super.key,
    required this.icon,
    required this.message,
    this.padding,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = AutolabCustomer.radiusInput,
    this.iconSpacing = AutolabCustomer.spacingSm,
    this.textHeight,
  });

  final IconData icon;
  final String message;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final double iconSpacing;
  final double? textHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(AutolabCustomer.spacingMd),
      decoration: BoxDecoration(
        color: backgroundColor ?? AutolabCustomer.customerSurfaceColor(context),
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: Row(
        children: [
          Icon(icon, color: AutolabCustomer.primary),
          SizedBox(width: iconSpacing),
          Expanded(
            child: Text(
              message,
              style: AutolabCustomer.caption.copyWith(
                color: AutolabCustomer.customerSecondaryTextColor(context),
                height: textHeight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
