import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../workshops/domain/entities/workshop.dart';

class NavigationHandler {
  static void handle(
    BuildContext context,
    int index, {
    List<Workshop>? workshops,
  }) {
    switch (index) {
      case 0:
        context.go('/home-customer');
        return;

      case 1:
        context.go('/home-customer?tab=map');
        return;

      case 2:
        context.go('/home-customer?tab=search');
        return;

      case 3:
        context.go('/home-customer?tab=cart');
        return;

      case 4:
        context.go('/home-customer?tab=profile');
        return;

      default:
        return;
    }
  }
}
