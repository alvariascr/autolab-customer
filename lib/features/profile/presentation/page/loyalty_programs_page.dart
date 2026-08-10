import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/autolab_customer.dart';
import '../../../../l10n/app_localizations.dart';

class LoyaltyProgramsPage extends StatelessWidget {
  const LoyaltyProgramsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AutolabCustomer.customerBackgroundColor(context),
      body: SafeArea(
        child: Column(
          children: [
            _LoyaltyProgramsHeader(
              title: l10n.garageOrders,
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                  return;
                }

                context.go('/home-customer?tab=profile');
              },
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AutolabCustomer.spacingXl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          color: AutolabCustomer.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.card_giftcard_rounded,
                          color: AutolabCustomer.primary,
                          size: 42,
                        ),
                      ),
                      const SizedBox(height: AutolabCustomer.spacingLg),
                      Text(
                        l10n.loyaltyProgramsComingSoonTitle,
                        textAlign: TextAlign.center,
                        style: AutolabCustomer.h2.copyWith(
                          color: AutolabCustomer.customerTextColor(context),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: AutolabCustomer.spacingSm),
                      Text(
                        l10n.loyaltyProgramsComingSoonMessage,
                        textAlign: TextAlign.center,
                        style: AutolabCustomer.body.copyWith(
                          color: AutolabCustomer.customerSecondaryTextColor(
                            context,
                          ),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: AutolabCustomer.spacingXl),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                              return;
                            }

                            context.go('/home-customer?tab=profile');
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AutolabCustomer.primary,
                            foregroundColor: AutolabCustomer.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: AutolabCustomer.spacingMd,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AutolabCustomer.radiusLg,
                              ),
                            ),
                          ),
                          child: Text(
                            l10n.loyaltyProgramsBackToGarage,
                            style: AutolabCustomer.body.copyWith(
                              color: AutolabCustomer.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoyaltyProgramsHeader extends StatelessWidget {
  const _LoyaltyProgramsHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final horizontalMargin = AutolabCustomer.responsiveScreenMargin(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalMargin,
        AutolabCustomer.spacingSm,
        horizontalMargin,
        0,
      ),
      child: SizedBox(
        height: 72,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Positioned(left: 0, top: 0, child: _LoyaltyHeaderLogo()),
            Positioned(
              left: 0,
              bottom: 0,
              child: _HeaderCircleButton(onTap: onBack),
            ),
            Positioned(
              bottom: 0,
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AutolabCustomer.h3.copyWith(
                  color: AutolabCustomer.customerTextColor(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCircleButton extends StatelessWidget {
  const _HeaderCircleButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: onTap,
        style: IconButton.styleFrom(
          backgroundColor: AutolabCustomer.customerSurfaceColor(context),
          foregroundColor: AutolabCustomer.customerSecondaryTextColor(context),
        ),
        icon: const Icon(
          Icons.arrow_back_rounded,
          size: AutolabCustomer.iconSm,
        ),
      ),
    );
  }
}

class _LoyaltyHeaderLogo extends StatelessWidget {
  const _LoyaltyHeaderLogo();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 58,
      height: 22,
      child: CustomPaint(painter: _LoyaltyHeaderLogoPainter()),
    );
  }
}

class _LoyaltyHeaderLogoPainter extends CustomPainter {
  const _LoyaltyHeaderLogoPainter();

  static const _sourceWidth = 622.0;
  static const _sourceHeight = 224.0;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _sourceWidth;
    final dy = (size.height - _sourceHeight * scale) / 2;
    canvas
      ..save()
      ..translate(0, dy)
      ..scale(scale);

    final paint = Paint()..color = AutolabCustomer.primary;
    for (final polygon in _polygons) {
      final path = Path()..moveTo(polygon.first.dx, polygon.first.dy);
      for (final point in polygon.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      path.close();
      canvas.drawPath(path, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  static const _polygons = [
    [
      Offset(503.87, 7.07),
      Offset(512.96, 35.05),
      Offset(542.39, 35.05),
      Offset(518.58, 52.35),
      Offset(527.68, 80.34),
      Offset(503.87, 63.04),
      Offset(480.07, 80.34),
      Offset(489.16, 52.35),
      Offset(465.35, 35.05),
      Offset(494.78, 35.05),
    ],
    [
      Offset(279.41, 7.07),
      Offset(404.43, 7.07),
      Offset(462.51, 109.9),
      Offset(542.39, 109.9),
      Offset(603.12, 216.93),
      Offset(397.95, 216.93),
    ],
    [
      Offset(18.88, 216.93),
      Offset(51.05, 160),
      Offset(22.67, 109.9),
      Offset(79.45, 109.74),
      Offset(137.46, 7.07),
      Offset(261.85, 7.07),
      Offset(380.35, 216.93),
      Offset(256, 216.93),
      Offset(199.66, 117.18),
      Offset(174.43, 161.84),
      Offset(205.94, 216.93),
    ],
  ];
}
