import 'package:flutter/material.dart';

import '../../../../core/theme/autolab_customer.dart';

class WorkshopAvatar extends StatelessWidget {
  const WorkshopAvatar({
    super.key,
    required this.imageUrl,
    required this.outerRadius,
    required this.innerRadius,
    required this.outerColor,
    required this.innerColor,
    this.fallbackIconSize = AutolabCustomer.iconMd,
    this.fallbackIconColor,
    this.fallbackIcon = Icons.storefront_outlined,
    this.borderColor,
  });

  final String imageUrl;
  final double outerRadius;
  final double innerRadius;
  final Color outerColor;
  final Color innerColor;
  final double fallbackIconSize;
  final Color? fallbackIconColor;
  final IconData fallbackIcon;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final normalizedImageUrl = imageUrl.trim();

    return Container(
      width: outerRadius * 2,
      height: outerRadius * 2,
      decoration: BoxDecoration(
        color: outerColor,
        shape: BoxShape.circle,
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: Center(
        child: CircleAvatar(
          radius: innerRadius,
          backgroundColor: innerColor,
          backgroundImage: normalizedImageUrl.isNotEmpty
              ? NetworkImage(normalizedImageUrl)
              : null,
          child: normalizedImageUrl.isEmpty
              ? Icon(
                  fallbackIcon,
                  size: fallbackIconSize,
                  color: fallbackIconColor,
                )
              : null,
        ),
      ),
    );
  }
}
