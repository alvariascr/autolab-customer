import 'package:flutter/material.dart';

class AuthCardShell extends StatelessWidget {
  const AuthCardShell({
    super.key,
    required this.cardWidth,
    required this.cardHeight,
    required this.logoSize,
    required this.child,
  });

  final double cardWidth;
  final double cardHeight;
  final double logoSize;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 15,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Padding(padding: const EdgeInsets.only(top: 140), child: child),
            Positioned(
              top: 0,
              child: Image.asset(
                'assets/images/virtual/Mesa de trabajo 10@2x.png',
                width: logoSize,
                height: logoSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
