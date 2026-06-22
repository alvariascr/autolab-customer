import 'package:flutter/material.dart';

import '../../../../core/theme/autolab_customer.dart';

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({
    super.key,
    required this.message,
    this.variant = AuthBannerVariant.error,
  });

  final String message;
  final AuthBannerVariant variant;

  @override
  Widget build(BuildContext context) {
    final palette = _AuthBannerPalette.fromVariant(variant);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AutolabCustomer.spacingSmd + 2,
        vertical: AutolabCustomer.spacingSmd,
      ),
      decoration: BoxDecoration(
        color: palette.background,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusInput),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: palette.iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(palette.icon, color: palette.iconColor, size: 18),
          ),
          const SizedBox(width: AutolabCustomer.spacingSm + 2),
          Expanded(
            child: Text(
              message,
              style: AutolabCustomer.body.copyWith(
                color: palette.text,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum AuthBannerVariant { error, success }

class _AuthBannerPalette {
  const _AuthBannerPalette({
    required this.background,
    required this.border,
    required this.shadow,
    required this.iconBackground,
    required this.iconColor,
    required this.text,
    required this.icon,
  });

  final Color background;
  final Color border;
  final Color shadow;
  final Color iconBackground;
  final Color iconColor;
  final Color text;
  final IconData icon;

  factory _AuthBannerPalette.fromVariant(AuthBannerVariant variant) {
    return switch (variant) {
      AuthBannerVariant.error => const _AuthBannerPalette(
        background: AutolabCustomer.authErrorBackground,
        border: AutolabCustomer.authErrorBorder,
        shadow: AutolabCustomer.authErrorShadow,
        iconBackground: AutolabCustomer.authErrorIconBackground,
        iconColor: AutolabCustomer.authErrorIcon,
        text: AutolabCustomer.authErrorText,
        icon: Icons.error_outline,
      ),
      AuthBannerVariant.success => const _AuthBannerPalette(
        background: AutolabCustomer.authSuccessBackground,
        border: AutolabCustomer.authSuccessBorder,
        shadow: AutolabCustomer.authSuccessShadow,
        iconBackground: AutolabCustomer.authSuccessIconBackground,
        iconColor: AutolabCustomer.authSuccessIcon,
        text: AutolabCustomer.authSuccessText,
        icon: Icons.check_circle_outline,
      ),
    };
  }
}
