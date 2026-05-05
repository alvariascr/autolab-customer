import 'package:flutter/material.dart';
import '../home/home_customer_page.dart';
import '../map/presentation/page/map_page.dart';
import '../profile/presentation/page/profile_page.dart';
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
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeCustomerPage()),
          (route) => false,
        );
        return;

      case 1:
        // Mapa
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MapPage()),
        );

        return;

      case 2:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeCustomerPage(
              initialIndex: 2,
              initialShowSearchBar: true,
            ),
          ),
          (route) => false,
        );
        return;

      case 3:
        // Carrito

        // Cuando tengas CartPage, usa esto:
        /*
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CartPage(),
          ),
        );
        */
        return;

      case 4:
        // Perfil
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
        return;

      default:
        return;
    }
  }
}
