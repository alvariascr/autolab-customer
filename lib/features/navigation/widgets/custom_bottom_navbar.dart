import 'package:flutter/material.dart';

import '../../../core/theme/autolab_customer.dart';
import '../../../l10n/app_localizations.dart';

class CustomBottomNavbar extends StatelessWidget {
  const CustomBottomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final isSearchSelected = currentIndex == 2;

    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalMargin = AutolabCustomer.responsiveDouble(
            context,
            compact: AutolabCustomer.spacingSmd,
            regular: AutolabCustomer.spacingScreen,
            tablet: AutolabCustomer.spacingXl,
          );
          final itemWidth = AutolabCustomer.responsiveDouble(
            context,
            compact: 42,
            regular: 50,
            tablet: 58,
          );
          final searchWidth = (constraints.maxWidth * 0.34).clamp(
            86.0,
            AutolabCustomer.isTabletWidth(context) ? 148.0 : 126.0,
          );

          return Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalMargin,
              AutolabCustomer.spacingSm - 2,
              horizontalMargin,
              bottomPadding > 0 ? 0 : AutolabCustomer.spacingSmd - 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_rounded,
                  label: l10n.navigationHome,
                  isSelected: currentIndex == 0,
                  width: itemWidth,
                  onTap: () => onTap(0),
                ),
                _NavItem(
                  icon: Icons.map_outlined,
                  selectedIcon: Icons.map_rounded,
                  label: l10n.navigationMap,
                  isSelected: currentIndex == 1,
                  width: itemWidth,
                  onTap: () => onTap(1),
                ),
                _SearchNavItem(
                  isSelected: isSearchSelected,
                  expandedWidth: searchWidth,
                  onTap: () => onTap(2),
                ),
                _NavItem(
                  icon: Icons.shopping_cart_outlined,
                  selectedIcon: Icons.shopping_cart_rounded,
                  label: l10n.navigationCart,
                  isSelected: currentIndex == 3,
                  width: itemWidth,
                  onTap: () => onTap(3),
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  selectedIcon: Icons.person_rounded,
                  label: l10n.navigationProfile,
                  isSelected: currentIndex == 4,
                  width: itemWidth,
                  onTap: () => onTap(4),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.width,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? AutolabCustomer.primary
        : AutolabCustomer.customerTextColor(context);
    final iconSize = AutolabCustomer.responsiveDouble(
      context,
      compact: AutolabCustomer.iconMd,
      regular: AutolabCustomer.iconLg - 4,
      tablet: AutolabCustomer.iconLg,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: color,
              size: iconSize,
            ),
            const SizedBox(height: AutolabCustomer.spacingXs - 1),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AutolabCustomer.caption.copyWith(
                color: color,
                fontSize: AutolabCustomer.isCompactWidth(context) ? 10 : null,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchNavItem extends StatelessWidget {
  const _SearchNavItem({
    required this.isSelected,
    required this.expandedWidth,
    required this.onTap,
  });

  final bool isSelected;
  final double expandedWidth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = AutolabCustomer.customerInvertedSurfaceColor(
      context,
    );
    final iconColor = AutolabCustomer.customerOnInvertedSurfaceColor(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        width: isSelected ? AutolabCustomer.spacingXxl : expandedWidth,
        height: AutolabCustomer.spacingXxl,
        margin: const EdgeInsets.only(bottom: AutolabCustomer.spacingMd),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Center(
          child: Icon(
            Icons.search_rounded,
            color: iconColor,
            size: AutolabCustomer.iconLg - 5,
          ),
        ),
      ),
    );
  }
}
