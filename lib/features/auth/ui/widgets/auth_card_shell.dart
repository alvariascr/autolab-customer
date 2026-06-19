import 'package:flutter/material.dart';

import '../../../../core/theme/autolab_customer.dart';

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
    return Container(
      width: cardWidth,
      height: cardHeight,
      color: AutolabCustomer.authBackgroundColor(context),
      child: child,
    );
  }
}
