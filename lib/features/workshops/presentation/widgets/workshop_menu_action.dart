import 'package:flutter/material.dart';

import '../../../../core/theme/autolab_customer.dart';

class WorkshopMenuAction extends StatelessWidget {
  const WorkshopMenuAction({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.enabled = true,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = enabled
        ? AutolabCustomer.customerTextColor(context)
        : AutolabCustomer.customerDisabledTextColor(context);

    return ListTile(
      enabled: enabled,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 30, color: foregroundColor),
      title: Text(
        title,
        style: AutolabCustomer.bodyLarge.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: subtitle == null ? null : Text(subtitle!),
      onTap: onTap,
    );
  }
}
