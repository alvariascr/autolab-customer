part of 'home_customer_content.dart';

class _AutolabHomeHeader extends StatelessWidget {
  const _AutolabHomeHeader({
    required this.state,
    required this.onLocationTap,
    required this.onNotificationTap,
  });

  final LocationState state;
  final VoidCallback onLocationTap;
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    final logoWidth = AutolabCustomer.responsiveDouble(
      context,
      compact: 88,
      regular: 104,
      tablet: 124,
    );
    return Column(
      children: [
        Row(
          children: [
            _AutolabLogoMark(width: logoWidth, height: logoWidth * 0.37),
            const Spacer(),
            CustomerNotificationBell(onTap: onNotificationTap),
          ],
        ),
        const SizedBox(height: AutolabCustomer.spacingSm),
        DeliveryLocationCard(state: state, onTap: onLocationTap),
      ],
    );
  }
}

class _AutolabLogoMark extends StatelessWidget {
  const _AutolabLogoMark({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _AutolabLogoPainter()),
    );
  }
}

class _AutolabLogoPainter extends CustomPainter {
  static const _sourceWidth = 622.0;
  static const _sourceHeight = 224.0;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _sourceWidth;
    final dy = (size.height - (_sourceHeight * scale)) / 2;
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
