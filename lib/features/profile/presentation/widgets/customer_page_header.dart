import 'package:flutter/material.dart';

import '../../../../core/theme/autolab_customer.dart';
import '../../../notifications/presentation/widgets/customer_notification_bell.dart';

class CustomerPageHeader extends StatelessWidget {
  const CustomerPageHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.onNotificationTap,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback? onNotificationTap;

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
            const Positioned(left: 0, top: 0, child: _CustomerHeaderLogo()),
            Positioned(
              left: 0,
              bottom: 0,
              child: _HeaderCircleButton(onTap: onBack),
            ),
            Positioned(
              left: 56,
              right: 56,
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
            if (onNotificationTap != null)
              Positioned(
                right: 0,
                bottom: 0,
                child: CustomerNotificationBell(onTap: onNotificationTap!),
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
    final tooltip = MaterialLocalizations.of(context).backButtonTooltip;

    return SizedBox(
      width: 48,
      height: 48,
      child: Tooltip(
        message: tooltip,
        child: Semantics(
          button: true,
          label: tooltip,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AutolabCustomer.customerSurfaceColor(context),
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: AutolabCustomer.customerSecondaryTextColor(
                        context,
                      ),
                      size: AutolabCustomer.iconSm,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomerHeaderLogo extends StatelessWidget {
  const _CustomerHeaderLogo();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 58,
      height: 22,
      child: CustomPaint(painter: _CustomerHeaderLogoPainter()),
    );
  }
}

class _CustomerHeaderLogoPainter extends CustomPainter {
  const _CustomerHeaderLogoPainter();

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
