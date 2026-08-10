import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../workshops/domain/entities/workshop.dart';

// Cuando tengas las pantallas, descomenta estos imports:
// import '../map/presentation/pages/map_page.dart';
// import '../cart/presentation/pages/cart_page.dart';
// import '../profile/presentation/pages/profile_page.dart';

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
        context.go('/cart');
        return;

      case 4:
        context.go('/home-customer?tab=garage');
        return;

      default:
        return;
    }
  }
}
