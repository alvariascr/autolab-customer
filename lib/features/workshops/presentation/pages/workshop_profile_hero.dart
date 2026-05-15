part of 'workshop_profile_page.dart';

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.workshop});

  final Workshop workshop;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: 340,
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
                  Color(0xB0000000),
                  Color(0x50000000),
                  Color(0xB0000000),
                ],
              ),
            ),
          ),
          Positioned(
            top: topPadding + 14,
            left: 16,
            child: _HeroIconButton(
              icon: Icons.close_rounded,
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                  return;
                }

                context.go('/home-customer');
              },
            ),
          ),
          Positioned(
            top: topPadding + 14,
            right: 16,
            child: Row(
              children: [
                _HeroIconButton(
                  icon: Icons.search_rounded,
                  onTap: () {
                    context.push('/search/workshops/${workshop.id}/products');
                  },
                ),
                const SizedBox(width: 10),
                _HeroIconButton(
                  icon: Icons.favorite_border_rounded,
                  onTap: () => _showSoon(context),
                ),
                const SizedBox(width: 10),
                _HeroIconButton(
                  icon: Icons.more_horiz_rounded,
                  onTap: () => _showBusinessOptions(context, workshop),
                ),
              ],
            ),
          ),
          Positioned(
            left: 28,
            right: 28,
            bottom: 52,
            child: Column(
              children: [
                Text(
                  '"${workshop.description.isNotEmpty ? workshop.description : AppLocalizations.of(context)!.workshopCardDescriptionFallback}"',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.workshopProfileScheduleSoon,
        ),
      ),
    );
  }

  void _showBusinessOptions(BuildContext context, Workshop workshop) {
    final rootContext = context;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MenuAction(
                  icon: Icons.search_rounded,
                  title: l10n.workshopProfileProductSearchHint,
                ),
                _MenuAction(
                  icon: Icons.calendar_month_outlined,
                  title: l10n.workshopProfileScheduleAction,
                  onTap: () => rootContext.push(
                    _ProfileActions.appointmentRoute(workshop),
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
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
        color: const Color(0xFF3D6B45),
        child: const Center(
          child: Icon(
            Icons.car_repair_outlined,
            size: 64,
            color: Colors.white70,
          ),
        ),
      );
    }

    return Image.network(
      workshop.coverUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, error, stackTrace) {
        return Container(
          color: const Color(0xFF3D6B45),
          child: const Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}

class _HeroIconButton extends StatelessWidget {
  const _HeroIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.42),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(icon, color: Colors.white, size: 28),
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
    final metadata = <Widget>[
      if (workshop.hasValidDeliveryRadius)
        Text(
          l10n.workshopCardCoveragePrefix(
            '${workshop.deliveryRadiusKm.toStringAsFixed(0)} km',
          ),
        ),
      if (workshop.offersHomeService) ...[
        if (workshop.hasValidDeliveryRadius) const Text('•'),
        Text(
          l10n.workshopProfileMobileServiceLabel,
          style: const TextStyle(
            color: Color(0xFF9B6A00),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ];

    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          Text(
            workshop.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF181411),
              fontWeight: FontWeight.w900,
              fontSize: 30,
            ),
          ),
          if (metadata.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 5,
              runSpacing: 5,
              children: metadata,
            ),
          ],
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
    return CircleAvatar(
      radius: 44,
      backgroundColor: Colors.white,
      child: CircleAvatar(
        radius: 39,
        backgroundColor: const Color(0xFFE9DDD2),
        backgroundImage: workshop.avatarUrl.isNotEmpty
            ? NetworkImage(workshop.avatarUrl)
            : null,
        child: workshop.avatarUrl.isEmpty
            ? const Icon(Icons.storefront_outlined, size: 34)
            : null,
      ),
    );
  }
}
