part of 'delivery_addresses_page.dart';

class _AddressesHeader extends StatelessWidget {
  const _AddressesHeader({
    required this.title,
    required this.addLabel,
    required this.onAdd,
    required this.onBack,
  });

  final String title;
  final String addLabel;
  final VoidCallback onAdd;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = AutolabCustomer.responsiveScreenMargin(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        AutolabCustomer.spacingSm,
        horizontalPadding,
        AutolabCustomer.spacingSm,
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _AddressesBackButton(onPressed: onBack),
              ),
              const AutolabLogoMark(width: 96, height: 36),
            ],
          ),
          const SizedBox(height: AutolabCustomer.spacingLg),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AutolabCustomer.h2.copyWith(
                    color: AutolabCustomer.customerTextColor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                onPressed: onAdd,
                style: TextButton.styleFrom(
                  foregroundColor: AutolabCustomer.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AutolabCustomer.spacingSm,
                  ),
                  minimumSize: const Size(0, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  addLabel,
                  style: AutolabCustomer.body.copyWith(
                    color: AutolabCustomer.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddressesBackButton extends StatelessWidget {
  const _AddressesBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AutolabCustomer.customerSoftSurfaceColor(context),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox.square(
          dimension: 36,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AutolabCustomer.customerSecondaryTextColor(context),
            size: AutolabCustomer.iconSm,
          ),
        ),
      ),
    );
  }
}

class _AddAddressButton extends StatelessWidget {
  const _AddAddressButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: AutolabCustomer.primaryButton,
        icon: const Icon(Icons.add_circle_outline_rounded),
        label: Text(
          l10n.garageAddressesAddNewAction,
          style: AutolabCustomer.bodyLarge.copyWith(
            color: AutolabCustomer.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _AddressIconBadge extends StatelessWidget {
  const _AddressIconBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: AutolabCustomer.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(
          color: AutolabCustomer.primary.withValues(alpha: 0.45),
        ),
      ),
      child: const Icon(
        Icons.location_on_outlined,
        color: AutolabCustomer.primary,
        size: AutolabCustomer.iconMd,
      ),
    );
  }
}

class _AddressCircleAction extends StatelessWidget {
  const _AddressCircleAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.destructive = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final foreground = destructive
        ? AutolabCustomer.primary
        : AutolabCustomer.customerTextColor(context);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: destructive
            ? AutolabCustomer.primary.withValues(alpha: 0.12)
            : AutolabCustomer.customerSurfaceColor(context),
        shape: CircleBorder(
          side: BorderSide(
            color: destructive
                ? AutolabCustomer.primary.withValues(alpha: 0.45)
                : AutolabCustomer.customerBorderColor(context),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 48,
            child: Icon(icon, color: foreground, size: AutolabCustomer.iconSm),
          ),
        ),
      ),
    );
  }
}

class _DeliveryAddressCard extends StatelessWidget {
  const _DeliveryAddressCard({
    required this.location,
    required this.isActive,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final CustomerLocation location;
  final bool isActive;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: AutolabCustomer.customerSoftSurfaceColor(context),
      borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard),
        child: Ink(
          padding: const EdgeInsets.all(AutolabCustomer.spacingMd),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard),
            border: Border.all(
              color: isActive
                  ? AutolabCustomer.primary.withValues(alpha: 0.85)
                  : AutolabCustomer.customerBorderColor(context),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const _AddressIconBadge(),
              const SizedBox(width: AutolabCustomer.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      location.displayLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AutolabCustomer.bodyLarge.copyWith(
                        color: AutolabCustomer.customerTextColor(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(height: AutolabCustomer.spacingXs),
                      _DefaultBadge(label: l10n.garageLocationsActiveLabel),
                    ],
                    const SizedBox(height: AutolabCustomer.spacingXs),
                    Text(
                      location.address,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AutolabCustomer.body.copyWith(
                        color: AutolabCustomer.customerSecondaryTextColor(
                          context,
                        ),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AutolabCustomer.spacingSmd),
              _AddressCircleAction(
                icon: Icons.edit_outlined,
                tooltip: l10n.cartEditAddressAction,
                onPressed: onEdit,
              ),
              const SizedBox(width: AutolabCustomer.spacingSm),
              _AddressCircleAction(
                icon: Icons.delete_outline_rounded,
                tooltip: l10n.cartDeleteAddressConfirm,
                onPressed: onDelete,
                destructive: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DefaultBadge extends StatelessWidget {
  const _DefaultBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AutolabCustomer.spacingSm,
        vertical: AutolabCustomer.spacingXs,
      ),
      decoration: BoxDecoration(
        color: AutolabCustomer.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusChip),
      ),
      child: Text(
        label,
        style: AutolabCustomer.label.copyWith(
          color: AutolabCustomer.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
