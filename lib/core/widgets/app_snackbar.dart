import 'package:flutter/material.dart';

import '../theme/autolab_customer.dart';

enum AppMessageType { success, warning, error }

void showAppSnackBar(
  BuildContext context, {
  required String message,
  required AppMessageType type,
}) {
  final theme = Theme.of(context);
  final config = switch (type) {
    AppMessageType.success => (
      icon: Icons.check_circle_outline,
      color: AutolabCustomer.successText,
      background: AutolabCustomer.successSoftBackground,
    ),
    AppMessageType.warning => (
      icon: Icons.info_outline,
      color: AutolabCustomer.warningText,
      background: AutolabCustomer.warningSoftBackground,
    ),
    AppMessageType.error => (
      icon: Icons.error_outline,
      color: theme.colorScheme.primary,
      background: AutolabCustomer.errorSoftBackground,
    ),
  };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        padding: EdgeInsets.zero,
        backgroundColor: AutolabCustomer.transparent,
        duration: const Duration(seconds: 4),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: config.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: config.color.withValues(alpha: 0.35)),
            boxShadow: const [
              BoxShadow(
                color: AutolabCustomer.shadowBlackStrong,
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(config.icon, color: config.color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AutolabCustomer.secondary,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
}
