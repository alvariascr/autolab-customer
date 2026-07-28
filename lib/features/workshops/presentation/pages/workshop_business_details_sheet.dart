part of 'workshop_profile_page.dart';

class _BusinessDetailsSheet extends StatelessWidget {
  const _BusinessDetailsSheet({required this.workshop});

  static const _todayBusinessHoursResolver =
      WorkshopTodayBusinessHoursResolver();

  final Workshop workshop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories = workshop.serviceCategories.isEmpty
        ? l10n.workshopProfileServicesEmpty
        : workshop.serviceCategories.join(' • ');

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.68,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              Stack(
                children: [
                  _LocationPreview(workshop: workshop),
                  Positioned(
                    top: 18,
                    left: 20,
                    child: _HeroIconButton(
                      icon: Icons.close_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const Positioned(
                    top: 10,
                    left: 0,
                    right: 0,
                    child: Center(child: _SheetDragHandle()),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workshop.name,
                      style: AutolabCustomer.h1.copyWith(
                        color: AutolabCustomer.customerTextColor(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      categories,
                      style: AutolabCustomer.bodyLarge.copyWith(
                        color: AutolabCustomer.customerSecondaryTextColor(
                          context,
                        ),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _InfoListRow(
                      icon: Icons.location_on_outlined,
                      title: workshop.locationAddress.isNotEmpty
                          ? workshop.locationAddress
                          : l10n.mapSheetFallbackAddress,
                      trailing: Icons.copy_rounded,
                    ),
                    const Divider(height: 28),
                    _InfoListRow(
                      icon: Icons.schedule_rounded,
                      title: _hoursSummary(context, workshop.businessHours),
                      trailing: Icons.keyboard_arrow_down_rounded,
                    ),
                    const Divider(height: 28),
                    _InfoListRow(
                      icon: Icons.local_shipping_outlined,
                      title: workshop.offersHomeService
                          ? l10n.workshopProfileHomeServiceAvailable
                          : l10n.workshopProfileHomeServiceUnavailable,
                      subtitle: workshop.hasValidDeliveryRadius
                          ? l10n.workshopProfileCoverageValue(
                              workshop.deliveryRadiusKm.toStringAsFixed(0),
                            )
                          : l10n.workshopProfileCoverageUnavailable,
                    ),
                    _InfoListRow(
                      icon: Icons.info_outline_rounded,
                      title: l10n.workshopProfileAboutTitle,
                      subtitle: workshop.description.isNotEmpty
                          ? workshop.description
                          : l10n.workshopCardDescriptionFallback,
                    ),
                    if (workshop.phone.isNotEmpty) ...[
                      const Divider(height: 28),
                      _InfoListRow(
                        icon: Icons.call_outlined,
                        title: workshop.phone,
                      ),
                    ],
                    if (workshop.paymentMethods.isNotEmpty) ...[
                      const Divider(height: 28),
                      _InfoListRow(
                        icon: Icons.payments_outlined,
                        title: l10n.workshopProfilePaymentMethodsTitle,
                        subtitle: workshop.paymentMethods.join(' • '),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () =>
                            _ProfileActions.openLocation(context, workshop),
                        icon: const Icon(Icons.map_outlined),
                        label: Text(l10n.workshopProfileOpenLocationAction),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _hoursSummary(BuildContext context, List<WorkshopBusinessHour> hours) {
    final l10n = AppLocalizations.of(context)!;

    if (hours.isEmpty) {
      return l10n.workshopProfileBusinessHoursEmpty;
    }

    final todayHours = _todayBusinessHoursResolver.resolve(hours);

    if (todayHours == null || todayHours.isClosed) {
      return l10n.workshopProfileClosed;
    }

    if (todayHours.closeTime.isEmpty) {
      return l10n.workshopProfileBusinessHoursEmpty;
    }

    return l10n.workshopProfileOpenUntil(_trimTime(todayHours.closeTime));
  }

  String _trimTime(String value) {
    return value.length >= 5 ? value.substring(0, 5) : value;
  }
}

class _SheetDragHandle extends StatelessWidget {
  const _SheetDragHandle();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AutolabCustomer.overlayWhiteStrong,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const SizedBox(width: 46, height: 5),
    );
  }
}

class _LocationPreview extends StatelessWidget {
  const _LocationPreview({required this.workshop});

  final Workshop workshop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasCoordinates = workshop.hasValidCoordinates;
    final position = hasCoordinates
        ? LatLng(workshop.latitude, workshop.longitude)
        : null;

    return SizedBox(
      height: 230,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (position != null)
            IgnorePointer(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: position,
                  zoom: 15.5,
                ),
                markers: {
                  Marker(
                    markerId: MarkerId('workshop-${workshop.id}'),
                    position: position,
                    infoWindow: InfoWindow(title: workshop.name),
                  ),
                },
                liteModeEnabled: true,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: false,
              ),
            )
          else
            DecoratedBox(
              decoration: const BoxDecoration(
                color: AutolabCustomer.customerLightMapFallback,
              ),
              child: Center(
                child: Icon(
                  Icons.location_on_outlined,
                  size: 64,
                  color: AutolabCustomer.customerSecondaryTextColor(context),
                ),
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AutolabCustomer.white.withValues(alpha: 0.08),
                    AutolabCustomer.white.withValues(alpha: 0.0),
                    AutolabCustomer.white.withValues(alpha: 0.18),
                  ],
                ),
              ),
            ),
          ),
          if (position != null)
            Positioned(
              right: 24,
              top: 86,
              child: Material(
                color: AutolabCustomer.customerElevatedSurfaceColor(context),
                borderRadius: BorderRadius.circular(14),
                elevation: 6,
                shadowColor: AutolabCustomer.shadowBlackStrong,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _ProfileActions.openLocation(context, workshop),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.workshopProfileDirectionsAction,
                          style: AutolabCustomer.body.copyWith(
                            color: AutolabCustomer.customerTextColor(context),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right_rounded, size: 22),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 18,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AutolabCustomer.customerElevatedSurfaceColor(
                  context,
                ).withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: AutolabCustomer.shadowBlackMedium,
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  workshop.locationAddress.isNotEmpty
                      ? workshop.locationAddress
                      : l10n.mapSheetFallbackAddress,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AutolabCustomer.body.copyWith(
                    color: AutolabCustomer.customerTextColor(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoListRow extends StatelessWidget {
  const _InfoListRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 30,
          color: AutolabCustomer.customerSecondaryTextColor(context),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AutolabCustomer.bodyLarge.copyWith(
                  color: AutolabCustomer.customerTextColor(context),
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  subtitle!,
                  style: AutolabCustomer.bodyLarge.copyWith(
                    color: AutolabCustomer.customerSecondaryTextColor(context),
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          Icon(
            trailing,
            size: 28,
            color: AutolabCustomer.customerHintColor(context),
          ),
        ],
      ],
    );
  }
}
