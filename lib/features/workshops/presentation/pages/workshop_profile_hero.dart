part of 'workshop_profile_page.dart';

class _ProfileHero extends StatefulWidget {
  const _ProfileHero({required this.workshop});

  final Workshop workshop;

  @override
  State<_ProfileHero> createState() => _ProfileHeroState();
}

class _ProfileHeroState extends State<_ProfileHero> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final workshop = widget.workshop;
    final topPadding = MediaQuery.paddingOf(context).top;
    final heroHeight = AutolabCustomer.responsiveDouble(
      context,
      compact: 220,
      regular: 260,
      tablet: 320,
    );

    return SizedBox(
      height: heroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _HeroImage(workshop: workshop),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66000000),
                  Color(0x22000000),
                  Color(0x99000000),
                ],
              ),
            ),
          ),
          Positioned(
            top: topPadding + AutolabCustomer.spacingSmd,
            left: AutolabCustomer.spacingSmd,
            child: _HeroIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              darkBackground: true,
              onTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                  return;
                }

                context.go('/home-customer');
              },
            ),
          ),
          Positioned(
            top: topPadding + AutolabCustomer.spacingSmd,
            right: AutolabCustomer.spacingSmd,
            child: Row(
              children: [
                _HeroIconButton(
                  icon: _isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  iconColor: AutolabCustomer.primary,
                  onTap: () {
                    setState(() => _isFavorite = !_isFavorite);
                  },
                ),
                const SizedBox(width: AutolabCustomer.spacingSm),
                _HeroIconButton(
                  icon: Icons.search_rounded,
                  onTap: () {
                    context.push('/search/workshops/${workshop.id}/products');
                  },
                ),
                const SizedBox(width: AutolabCustomer.spacingSm),
                _HeroIconButton(
                  icon: Icons.more_horiz_rounded,
                  onTap: () => _showBusinessOptions(context, workshop),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBusinessOptions(BuildContext context, Workshop workshop) {
    final rootContext = context;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AutolabCustomer.customerElevatedSurfaceColor(context),
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AutolabCustomer.radiusModal),
        ),
      ),
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AutolabCustomer.spacingLg,
              AutolabCustomer.spacingSm,
              AutolabCustomer.spacingLg,
              AutolabCustomer.spacingLg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MenuAction(
                  icon: Icons.search_rounded,
                  title: l10n.workshopProfileProductSearchHint,
                  onTap: () {
                    rootContext.push(
                      '/search/workshops/${workshop.id}/products',
                    );
                  },
                ),
                _MenuAction(
                  icon: Icons.calendar_month_outlined,
                  title: l10n.workshopProfileScheduleAction,
                  onTap: () => rootContext.push(
                    _ProfileActions.appointmentRoute(workshop.id),
                  ),
                ),
                _MenuAction(
                  icon: Icons.call_outlined,
                  title: l10n.workshopProfileCallAction,
                  enabled: workshop.phone.isNotEmpty,
                  onTap: () =>
                      _ProfileActions.launchPhone(rootContext, workshop.phone),
                ),
                _MenuAction(
                  icon: Icons.info_outline_rounded,
                  title: l10n.workshopProfileDetailsTitle,
                  subtitle: l10n.workshopProfileOpenLocationAction,
                  onTap: () => _showBusinessDetails(rootContext, workshop),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBusinessDetails(BuildContext context, Workshop workshop) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AutolabCustomer.customerElevatedSurfaceColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AutolabCustomer.radiusModal),
        ),
      ),
      builder: (context) {
        return _BusinessDetailsSheet(workshop: workshop);
      },
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.workshop});

  final Workshop workshop;

  @override
  Widget build(BuildContext context) {
    if (workshop.coverUrl.isEmpty) {
      return Container(
        color: AutolabCustomer.customerImageFallbackColor(context),
        child: Icon(
          Icons.car_repair_outlined,
          size: 64,
          color: AutolabCustomer.customerSecondaryTextColor(context),
        ),
      );
    }

    return Image.network(
      workshop.coverUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, error, stackTrace) {
        return Container(
          color: AutolabCustomer.customerImageFallbackColor(context),
          child: Icon(
            Icons.image_not_supported_outlined,
            color: AutolabCustomer.customerSecondaryTextColor(context),
          ),
        );
      },
    );
  }
}

class _HeroIconButton extends StatelessWidget {
  const _HeroIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.darkBackground = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final bool darkBackground;

  @override
  Widget build(BuildContext context) {
    final buttonSize = AutolabCustomer.responsiveDouble(
      context,
      compact: 38,
      regular: 44,
      tablet: 50,
    );

    return Material(
      color: darkBackground
          ? AutolabCustomer.secondary.withValues(alpha: 0.68)
          : AutolabCustomer.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: buttonSize,
          height: buttonSize,
          child: Icon(
            icon,
            color:
                iconColor ??
                (darkBackground
                    ? AutolabCustomer.white
                    : AutolabCustomer.secondary),
            size: AutolabCustomer.responsiveDouble(
              context,
              compact: 20,
              regular: 24,
              tablet: 28,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderSummary extends StatelessWidget {
  const _HeaderSummary({required this.workshop});

  final Workshop workshop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final titleSize = AutolabCustomer.responsiveDouble(
      context,
      compact: 24,
      regular: 28,
      tablet: 34,
    );

    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          Text(
            workshop.name,
            textAlign: TextAlign.center,
            style: AutolabCustomer.h1.copyWith(
              color: AutolabCustomer.customerTextColor(context),
              fontWeight: FontWeight.w900,
              fontSize: titleSize,
            ),
          ),
          const SizedBox(height: AutolabCustomer.spacingSmd),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AutolabCustomer.spacingSm,
            runSpacing: AutolabCustomer.spacingSm,
            children: [
              _ProfileMetaChip(
                icon: Icons.near_me_rounded,
                label: workshop.offersHomeService
                    ? l10n.workshopProfileMobileServiceLabel
                    : l10n.workshopProfileDetailsTitle,
              ),
              if (workshop.hasValidDeliveryRadius)
                _ProfileMetaChip(
                  icon: Icons.local_shipping_outlined,
                  label: l10n.workshopCardCoveragePrefix(
                    '${workshop.deliveryRadiusKm.toStringAsFixed(0)} km',
                  ),
                ),
              const _ProfileMetaChip(icon: Icons.star_rounded, label: '5.0'),
            ],
          ),
          if (workshop.locationAddress.isNotEmpty) ...[
            const SizedBox(height: AutolabCustomer.spacingMd),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: AutolabCustomer.primary,
                  size: AutolabCustomer.iconLg,
                ),
                const SizedBox(width: AutolabCustomer.spacingSm),
                Flexible(
                  child: Text(
                    workshop.locationAddress,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AutolabCustomer.body.copyWith(
                      color: AutolabCustomer.customerTextColor(context),
                      fontSize: AutolabCustomer.responsiveDouble(
                        context,
                        compact: 13,
                        regular: 15,
                        tablet: 18,
                      ),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileMetaChip extends StatelessWidget {
  const _ProfileMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AutolabCustomer.spacingSmd,
        vertical: AutolabCustomer.spacingXs + 2,
      ),
      decoration: BoxDecoration(
        color: AutolabCustomer.customerChipBackgroundColor(context),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AutolabCustomer.primary,
            size: AutolabCustomer.iconSm,
          ),
          const SizedBox(width: AutolabCustomer.spacingSm),
          Text(
            label,
            style: AutolabCustomer.body.copyWith(
              color: AutolabCustomer.customerTextColor(context),
              fontWeight: FontWeight.w600,
              fontSize: AutolabCustomer.responsiveDouble(
                context,
                compact: 12,
                regular: 13,
                tablet: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkshopAvatar extends StatelessWidget {
  const _WorkshopAvatar({required this.workshop});

  final Workshop workshop;

  @override
  Widget build(BuildContext context) {
    final outerRadius = AutolabCustomer.responsiveDouble(
      context,
      compact: 52,
      regular: 62,
      tablet: 72,
    );

    return CircleAvatar(
      radius: outerRadius,
      backgroundColor: AutolabCustomer.background,
      child: CircleAvatar(
        radius: outerRadius - 5,
        backgroundColor: AutolabCustomer.background,
        backgroundImage: workshop.avatarUrl.isNotEmpty
            ? NetworkImage(workshop.avatarUrl)
            : null,
        child: workshop.avatarUrl.isEmpty
            ? const Icon(
                Icons.storefront_outlined,
                size: AutolabCustomer.iconLg,
                color: AutolabCustomer.secondary,
              )
            : null,
      ),
    );
  }
}
