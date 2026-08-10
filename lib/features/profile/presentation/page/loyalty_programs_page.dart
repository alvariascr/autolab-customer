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
    final scale = (size.width / _sourceWidth).clamp(
      0.0,
      size.height / _sourceHeight,
    );
    final dx = (size.width - _sourceWidth * scale) / 2;
    final dy = (size.height - _sourceHeight * scale) / 2;

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale);

    final paint = Paint()
      ..color = AutolabCustomer.primary
      ..style = PaintingStyle.fill;
    final starPaint = Paint()
      ..color = AutolabCustomer.primary
      ..style = PaintingStyle.fill;

    final left = Path()
      ..moveTo(0, 169)
      ..lineTo(65, 60)
      ..lineTo(185, 60)
      ..lineTo(246, 169)
      ..lineTo(154, 169)
      ..lineTo(127, 120)
      ..lineTo(97, 169)
      ..close();
    final center = Path()
      ..moveTo(220, 60)
      ..lineTo(338, 60)
      ..lineTo(400, 169)
      ..lineTo(309, 169)
      ..lineTo(280, 119)
      ..lineTo(252, 169)
      ..lineTo(160, 169)
      ..close();
    final right = Path()
      ..moveTo(360, 60)
      ..lineTo(482, 60)
      ..lineTo(548, 169)
      ..lineTo(455, 169)
      ..lineTo(425, 119)
      ..lineTo(398, 169)
      ..lineTo(306, 169)
      ..close();

    canvas
      ..drawPath(left, paint)
      ..drawPath(center, paint)
      ..drawPath(right, paint);

    final star = Path()
      ..moveTo(522, 21)
      ..lineTo(535, 48)
      ..lineTo(565, 52)
      ..lineTo(543, 73)
      ..lineTo(548, 103)
      ..lineTo(522, 89)
      ..lineTo(495, 103)
      ..lineTo(500, 73)
      ..lineTo(478, 52)
      ..lineTo(509, 48)
      ..close();
    canvas.drawPath(star, starPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
