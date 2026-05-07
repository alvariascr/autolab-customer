import 'package:flutter/material.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: palette.background,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(12),
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
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: palette.text,
                fontSize: 14,
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
        background: Color(0xFFFFF1F0),
        border: Color(0xFFFFC9C5),
        shadow: Color(0x14D92D20),
        iconBackground: Color(0xFFFFE2DF),
        iconColor: Color(0xFFD92D20),
        text: Color(0xFFB42318),
        icon: Icons.error_outline,
      ),
      AuthBannerVariant.success => const _AuthBannerPalette(
        background: Color(0xFFF0FDF4),
        border: Color(0xFFBBF7D0),
        shadow: Color(0x1422C55E),
        iconBackground: Color(0xFFDCFCE7),
        iconColor: Color(0xFF16A34A),
        text: Color(0xFF166534),
        icon: Icons.check_circle_outline,
      ),
    };
  }
}
