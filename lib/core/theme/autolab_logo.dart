import 'package:flutter/material.dart';

import 'autolab_customer.dart';

class AutolabLogoMark extends StatelessWidget {
  const AutolabLogoMark({
    super.key,
    required this.width,
    required this.height,
    this.color = AutolabCustomer.primary,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _AutolabLogoPainter(color)),
    );
  }
}

class _AutolabLogoPainter extends CustomPainter {
  const _AutolabLogoPainter(this.color);

  final Color color;

  static const _sourceWidth = 622.0;
  static const _sourceHeight = 224.0;
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
      Offset(279.41, 7.07),
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
      Offset(18.88, 216.93),
    ],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _sourceWidth;
    final dy = (size.height - (_sourceHeight * scale)) / 2;
    final paint = Paint()..color = color;
    final path = Path();

    canvas
      ..save()
      ..translate(0, dy)
      ..scale(scale);

    for (final polygon in _polygons) {
      path
        ..reset()
        ..moveTo(polygon.first.dx, polygon.first.dy);

      for (final point in polygon.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }

      path.close();
      canvas.drawPath(path, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AutolabLogoPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
