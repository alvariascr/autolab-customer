import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../home/home_customer_page.dart';
import '../map/presentation/page/map_page.dart';
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
      _setInitialIndex(widget.initialIndex);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF050606) : Colors.white,
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
          const ProfilePage(showBottomNavigation: false),
          const _ComingSoonTab(),
        ],
      ),
      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: _navIndex,
        onTap: _handleNavigation,
      ),
    );
  }
}

class _ComingSoonTab extends StatelessWidget {
  const _ComingSoonTab();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF050606) : Colors.white;
    final textColor = isDark
        ? const Color(0xFFF4E9E9)
        : const Color(0xFF181411);
    final secondaryTextColor = isDark
        ? const Color(0xFFA9A9A9)
        : const Color(0xFF6B5F57);

    return ColoredBox(
      color: backgroundColor,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.shopping_cart_outlined,
                  color: Color(0xFFFF281B),
                  size: 46,
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.navigationCartComingSoonTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.navigationCartComingSoonMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
