import 'package:flutter/material.dart';

import '../../../core/theme/autolab_customer.dart';

class LocationOptionTile extends StatelessWidget {
  const LocationOptionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final textColor = enabled
        ? AutolabCustomer.customerTextColor(context)
        : AutolabCustomer.customerDisabledTextColor(context);
    final secondaryTextColor = enabled
        ? AutolabCustomer.customerSecondaryTextColor(context)
        : AutolabCustomer.customerDisabledTextColor(context);

    return Material(
      color: AutolabCustomer.customerSoftSurfaceColor(context),
      borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard + 4),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard + 4),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AutolabCustomer.spacingMd,
          vertical: AutolabCustomer.spacingXs,
        ),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AutolabCustomer.customerElevatedSurfaceColor(context),
            borderRadius: BorderRadius.circular(AutolabCustomer.radiusInput),
          ),
          child: Icon(icon, color: textColor, size: AutolabCustomer.iconSm - 1),
        ),
        title: Text(
          title,
          style: AutolabCustomer.body.copyWith(
            color: textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AutolabCustomer.caption.copyWith(
            color: secondaryTextColor,
            height: 1.35,
          ),
        ),
        trailing: Icon(
          enabled ? Icons.arrow_forward_ios_rounded : Icons.schedule_rounded,
          size: enabled ? AutolabCustomer.iconXs - 2 : AutolabCustomer.iconXs,
          color: secondaryTextColor,
        ),
      ),
    );
  }
}
