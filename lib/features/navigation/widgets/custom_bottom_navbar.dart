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
            compact: AutolabCustomer.spacingSm,
            regular: AutolabCustomer.spacingSmd,
            tablet: AutolabCustomer.spacingXl,
          );
          final itemWidth = AutolabCustomer.responsiveDouble(
            context,
            compact: 44,
            regular: 52,
            tablet: 58,
          );
          final searchWidth = (constraints.maxWidth * 0.28).clamp(
            76.0,
            AutolabCustomer.isTabletWidth(context) ? 140.0 : 108.0,
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
                  icon: Icons.garage_outlined,
                  selectedIcon: Icons.garage_rounded,
                  assetIcon: 'assets/images/icons/garaje_privado.png',
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
    this.assetIcon,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String? assetIcon;
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
      compact: AutolabCustomer.iconSm,
      regular: AutolabCustomer.iconMd,
      tablet: AutolabCustomer.iconLg,
    );
    final labelSize = AutolabCustomer.responsiveDouble(
      context,
      compact: 8.5,
      regular: 9.5,
      tablet: 11,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            assetIcon != null
                ? ImageIcon(
                    AssetImage(assetIcon!),
                    color: color,
                    size: iconSize,
                  )
                : Icon(
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
                fontSize: labelSize,
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
    final buttonSize = AutolabCustomer.responsiveDouble(
      context,
      compact: 40,
      regular: 44,
      tablet: AutolabCustomer.spacingXxl,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        width: isSelected ? buttonSize : expandedWidth,
        height: buttonSize,
        margin: EdgeInsets.only(
          bottom: AutolabCustomer.responsiveDouble(
            context,
            compact: AutolabCustomer.spacingSmd,
            regular: AutolabCustomer.spacingSmd,
            tablet: AutolabCustomer.spacingMd,
          ),
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Center(
          child: Icon(
            Icons.search_rounded,
            color: iconColor,
            size: AutolabCustomer.responsiveDouble(
              context,
              compact: AutolabCustomer.iconSm,
              regular: AutolabCustomer.iconMd,
              tablet: AutolabCustomer.iconLg - 5,
            ),
          ),
        ),
      ),
    );
  }
}
