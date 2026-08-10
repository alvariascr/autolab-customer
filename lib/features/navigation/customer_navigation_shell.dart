import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/app_injection.dart';
import '../../core/theme/autolab_customer.dart';
import '../cart/application/cart_cubit.dart';
import '../cart/presentation/pages/cart_page.dart';
import '../home/home_customer_page.dart';
import '../map/presentation/page/map_page.dart';
import '../profile/application/garage_vehicle_controller.dart';
import '../profile/presentation/page/profile_page.dart';
import 'widgets/custom_bottom_navbar.dart';

class CustomerNavigationShell extends StatefulWidget {
  const CustomerNavigationShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<CustomerNavigationShell> createState() =>
      _CustomerNavigationShellState();
}

class _CustomerNavigationShellState extends State<CustomerNavigationShell> {
  final HomeCustomerController _homeController = HomeCustomerController();
  int _navIndex = 0;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _setInitialIndex(widget.initialIndex);
  }

  @override
  void didUpdateWidget(covariant CustomerNavigationShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      setState(() {
        _setInitialIndex(widget.initialIndex);
      });
    }
  }

  void _setInitialIndex(int index) {
    _navIndex = index;
    _pageIndex = switch (index) {
      0 => 0,
      1 => 1,
      3 => 3,
      4 => 2,
      _ => 0,
    };
  }

  void _handleNavigation(int index) {
    if (index == 0) {
      setState(() {
        _navIndex = 0;
        _pageIndex = 0;
      });
      _homeController.closeSearch();
      return;
    }

    if (index == 2) {
      setState(() {
        _navIndex = 2;
        _pageIndex = 0;
      });
      _homeController.openSearch();
      return;
    }

    setState(() {
      _navIndex = index;
      _pageIndex = switch (index) {
        0 => 0,
        1 => 1,
        3 => 3,
        4 => 2,
        _ => 0,
      };
    });
  }

  void _handleSearchClosed() {
    if (_navIndex != 2) {
      return;
    }

    setState(() {
      _navIndex = 0;
      _pageIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CartCubit>(),
      child: Scaffold(
        backgroundColor: AutolabCustomer.customerBackgroundColor(context),
        extendBody: true,
        body: IndexedStack(
          index: _pageIndex,
          children: [
            HomeCustomerPage(
              controller: _homeController,
              showBottomNavigation: false,
              onSearchClosed: _handleSearchClosed,
            ),
            const MapPage(showBottomNavigation: false),
            ProfilePage(
              showBottomNavigation: false,
              garageVehicleController: sl<GarageVehicleController>(),
            ),
            const CartPage(),
          ],
        ),
        bottomNavigationBar: CustomBottomNavbar(
          currentIndex: _navIndex,
          onTap: _handleNavigation,
        ),
      ),
    );
  }
}
