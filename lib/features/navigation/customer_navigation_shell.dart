import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/di/app_injection.dart';
import '../../core/theme/autolab_customer.dart';
import '../cart/application/cart_cubit.dart';
import '../cart/presentation/pages/cart_page.dart';
import '../home/home_customer_page.dart';
import '../map/presentation/page/map_page.dart';
import '../profile/application/garage_vehicle_controller.dart';
import '../profile/presentation/page/profile_page.dart';
import 'navigation_handler.dart';
import 'widgets/custom_bottom_navbar.dart';

class CustomerNavigationShell extends StatefulWidget {
  const CustomerNavigationShell({super.key, this.initialIndex});

  /// Which bottom-nav tab to show. Null means "whatever the customer had
  /// last selected" (see [_CustomerNavigationShellState._lastNavIndex]) --
  /// routes that don't carry an explicit `?tab=` (e.g. a bare
  /// `/home-customer` reached after the router re-evaluates a redirect,
  /// or a back-navigation fallback) should not silently reset the customer
  /// to the home tab.
  final int? initialIndex;

  @override
  State<CustomerNavigationShell> createState() =>
      _CustomerNavigationShellState();
}

class _CustomerNavigationShellState extends State<CustomerNavigationShell> {
  // Persists across rebuilds/instances of this shell (module-level state,
  // not per-widget) so returning to /home-customer without an explicit tab
  // remembers where the customer actually was.
  static int _lastNavIndex = 0;
  static String? _lastAuthUserId;

  final HomeCustomerController _homeController = HomeCustomerController();
  late final CartCubit _cartCubit;
  int _navIndex = 0;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _cartCubit = sl<CartCubit>();
    _resetRememberedTabIfUserChanged();
    _setInitialIndex(widget.initialIndex ?? _lastNavIndex);
    _refreshCartIfSelected();
  }

  @override
  void didUpdateWidget(covariant CustomerNavigationShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final targetIndex = widget.initialIndex;
    if (targetIndex != null &&
        (oldWidget.initialIndex != targetIndex || _navIndex != targetIndex)) {
      setState(() {
        _setInitialIndex(targetIndex);
      });
      _refreshCartIfSelected();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _setInitialIndex(int index) {
    _navIndex = index;
    _lastNavIndex = index;
    _lastAuthUserId = _currentAuthUserId();
    _pageIndex = switch (index) {
      0 => 0,
      1 => 1,
      2 => 0,
      3 => 3,
      4 => 2,
      _ => 0,
    };
  }

  void _resetRememberedTabIfUserChanged() {
    final currentUserId = _currentAuthUserId();
    if (_lastAuthUserId != null && _lastAuthUserId != currentUserId) {
      _lastNavIndex = 0;
    }
    _lastAuthUserId = currentUserId;
  }

  String? _currentAuthUserId() {
    if (!sl.isRegistered<SupabaseClient>()) {
      return null;
    }
    return sl<SupabaseClient>().auth.currentUser?.id;
  }

  void _handleNavigation(int index) {
    if (index == 0) {
      setState(() {
        _navIndex = 0;
        _lastNavIndex = 0;
        _pageIndex = 0;
      });
      _homeController.closeSearch();
      NavigationHandler.handle(context, index);
      return;
    }

    if (index == 2) {
      setState(() {
        _navIndex = 2;
        _lastNavIndex = 2;
        _pageIndex = 0;
      });
      _homeController.openSearch();
      NavigationHandler.handle(context, index);
      return;
    }

    setState(() {
      _navIndex = index;
      _lastNavIndex = index;
      _pageIndex = switch (index) {
        0 => 0,
        1 => 1,
        3 => 3,
        4 => 2,
        _ => 0,
      };
    });
    _refreshCartIfSelected();
    NavigationHandler.handle(context, index);
  }

  void _handleSearchClosed() {
    if (_navIndex != 2) {
      return;
    }

    setState(() {
      _navIndex = 0;
      _lastNavIndex = 0;
      _pageIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cartCubit,
      child: Scaffold(
        backgroundColor: AutolabCustomer.customerBackgroundColor(context),
        extendBody: true,
        body: IndexedStack(
          index: _pageIndex,
          children: [
            HomeCustomerPage(
              controller: _homeController,
              initialIndex: _navIndex == 2 ? 2 : 0,
              initialShowSearchBar: _navIndex == 2,
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

  void _refreshCartIfSelected() {
    if (_navIndex == 3) {
      unawaited(_cartCubit.reloadPersistedCart());
    }
  }
}
