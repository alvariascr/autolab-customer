import 'package:flutter/material.dart';

import '../../../../core/location/current_location.dart';
import '../../../../core/theme/autolab_customer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/workshop.dart';
import '../../domain/services/workshop_distance_calculator.dart';

class WorkshopCard extends StatelessWidget {
  final Workshop workshop;
  final CurrentLocation? referenceLocation;
  final bool compact;

  const WorkshopCard({
    super.key,
    required this.workshop,
    this.referenceLocation,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final distanceLabel = _distanceLabel(context);
    final coverHeight = compact
        ? AutolabCustomer.responsiveDouble(
            context,
            compact: 104,
            regular: 118,
            tablet: 126,
          )
        : AutolabCustomer.responsiveDouble(
            context,
            compact: 106,
            regular: 120,
            tablet: 140,
          );
    final colors = _WorkshopCardColors.of(context);

    return Container(
      width: double.infinity,
      height: compact ? null : double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard + 2),
        border: Border.all(color: AutolabCustomer.primary, width: 1.2),
      ),
      child: Column(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AutolabCustomer.radiusCard + 2),
            ),
            child: workshop.coverUrl.isNotEmpty
                ? Image.network(
                    workshop.coverUrl,
                    height: coverHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, stackTrace) => Container(
                      height: coverHeight,
                      color: colors.imageFallback,
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: colors.secondaryText,
                        ),
                      ),
                    ),
                  )
                : Container(
                    height: coverHeight,
                    color: colors.imageFallback,
                    child: Center(
                      child: Icon(Icons.image, color: colors.secondaryText),
                    ),
                  ),
          ),
          if (compact)
            Padding(
              padding: const EdgeInsets.all(AutolabCustomer.spacingSmd),
              child: _WorkshopCardBody(
                workshop: workshop,
                distanceLabel: distanceLabel,
                compact: true,
              ),
            )
          else
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AutolabCustomer.spacingSmd,
                  AutolabCustomer.spacingSmd,
                  AutolabCustomer.spacingSmd,
                  AutolabCustomer.spacingSmd - 2,
                ),
                child: _WorkshopCardBody(
                  workshop: workshop,
                  distanceLabel: distanceLabel,
                  compact: false,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String? _distanceLabel(BuildContext context) {
    final location = referenceLocation;
    if (location == null || !location.hasValidCoordinates) {
      return null;
    }

    final distance = WorkshopDistanceCalculator.distanceInKm(
      currentLocation: location,
      workshop: workshop,
    );

    return AppLocalizations.of(context)!.workshopCardDistancePrefix(
      WorkshopDistanceCalculator.formatKm(distance),
    );
  }
}

class _WorkshopCardBody extends StatelessWidget {
  const _WorkshopCardBody({
    required this.workshop,
    required this.distanceLabel,
    required this.compact,
  });

  final Workshop workshop;
  final String? distanceLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = _WorkshopCardColors.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: compact
              ? AutolabCustomer.responsiveDouble(
                  context,
                  compact: 18,
                  regular: 20,
                  tablet: 22,
                )
              : AutolabCustomer.responsiveDouble(
                  context,
                  compact: 20,
                  regular: 24,
                  tablet: 28,
                ),
          backgroundColor: colors.avatarBackground,
          backgroundImage: workshop.avatarUrl.isNotEmpty
              ? NetworkImage(workshop.avatarUrl)
              : null,
          child: workshop.avatarUrl.isEmpty
              ? Icon(Icons.store, color: colors.iconOnAvatar)
              : null,
        ),
        const SizedBox(width: AutolabCustomer.spacingSmd),
        Expanded(
          child: Column(
            mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                workshop.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AutolabCustomer.bodyLarge.copyWith(
                  color: colors.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: compact ? 6 : 4),
              SizedBox(
                height: compact ? null : 22,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      if (distanceLabel != null) ...[
                        _InfoChip(
                          icon: Icons.near_me_outlined,
                          label: distanceLabel!,
                        ),
                        const SizedBox(width: 6),
                      ],
                      _InfoChip(
                        icon: Icons.local_shipping_outlined,
                        label: l10n.workshopCardCoveragePrefix(
                          WorkshopDistanceCalculator.formatKm(
                            workshop.deliveryRadiusKm,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (workshop.locationAddress.isNotEmpty) ...[
                SizedBox(height: compact ? 8 : 5),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: AutolabCustomer.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        workshop.locationAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AutolabCustomer.caption.copyWith(
                          color: colors.text,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: compact ? 6 : 4),
              if (compact)
                Text(
                  workshop.description.isNotEmpty
                      ? workshop.description
                      : l10n.workshopCardDescriptionFallback,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AutolabCustomer.caption.copyWith(color: colors.text),
                )
              else
                Expanded(
                  child: Text(
                    workshop.description.isNotEmpty
                        ? workshop.description
                        : l10n.workshopCardDescriptionFallback,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AutolabCustomer.caption.copyWith(
                      color: colors.text,
                      height: 1.18,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = _WorkshopCardColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: colors.chipBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AutolabCustomer.primary),
          const SizedBox(width: 3),
          Text(
            label,
            style: AutolabCustomer.label.copyWith(
              color: colors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkshopCardColors {
  const _WorkshopCardColors({
    required this.surface,
    required this.imageFallback,
    required this.text,
    required this.secondaryText,
    required this.avatarBackground,
    required this.iconOnAvatar,
    required this.chipBackground,
  });

  final Color surface;
  final Color imageFallback;
  final Color text;
  final Color secondaryText;
  final Color avatarBackground;
  final Color iconOnAvatar;
  final Color chipBackground;

  static _WorkshopCardColors of(BuildContext context) {
    return _WorkshopCardColors(
      surface: AutolabCustomer.customerElevatedSurfaceColor(context),
      imageFallback: AutolabCustomer.customerImageFallbackColor(context),
      text: AutolabCustomer.customerTextColor(context),
      secondaryText: AutolabCustomer.customerSecondaryTextColor(context),
      avatarBackground: AutolabCustomer.background,
      iconOnAvatar: AutolabCustomer.secondary,
      chipBackground: AutolabCustomer.customerChipBackgroundColor(context),
    );
  }
}
