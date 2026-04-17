import 'package:flutter/material.dart';

import '../../../../core/location/current_location.dart';
import '../../../../core/theme/app_text_styles.dart';
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
    final distanceLabel = _distanceLabel;
    final coverHeight = compact ? 130.0 : 112.0;

    return Container(
      width: double.infinity,
      height: compact ? null : double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: workshop.coverUrl.isNotEmpty
                ? Image.network(
                    workshop.coverUrl,
                    height: coverHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, stackTrace) => Container(
                      height: coverHeight,
                      color: Colors.grey.shade300,
                      child: const Center(
                        child: Icon(Icons.image_not_supported),
                      ),
                    ),
                  )
                : Container(
                    height: coverHeight,
                    color: Colors.grey.shade300,
                    child: const Center(child: Icon(Icons.image)),
                  ),
          ),
          if (compact)
            Padding(
              padding: const EdgeInsets.all(10),
              child: _WorkshopCardBody(
                workshop: workshop,
                distanceLabel: distanceLabel,
                compact: true,
              ),
            )
          else
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
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

  String? get _distanceLabel {
    final location = referenceLocation;
    if (location == null || !location.hasValidCoordinates) {
      return null;
    }

    final distance = WorkshopDistanceCalculator.distanceInKm(
      currentLocation: location,
      workshop: workshop,
    );

    return 'A ${WorkshopDistanceCalculator.formatKm(distance)}';
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: workshop.avatarUrl.isNotEmpty
              ? NetworkImage(workshop.avatarUrl)
              : null,
          child: workshop.avatarUrl.isEmpty ? const Icon(Icons.store) : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                workshop.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.normal,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (distanceLabel != null)
                    _InfoChip(
                      icon: Icons.near_me_outlined,
                      label: distanceLabel!,
                    ),
                  _InfoChip(
                    icon: Icons.local_shipping_outlined,
                    label:
                        'Cobertura ${WorkshopDistanceCalculator.formatKm(workshop.deliveryRadiusKm)}',
                  ),
                ],
              ),
              if (workshop.locationAddress.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Color(0xFF6B5F57),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        workshop.locationAddress,
                        maxLines: compact ? null : 1,
                        overflow: compact
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: AppTextStyles.small.copyWith(
                          color: const Color(0xFF6B5F57),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              if (compact)
                Text(
                  workshop.description.isNotEmpty
                      ? workshop.description
                      : 'Sin descripción disponible',
                  style: AppTextStyles.small,
                )
              else
                Expanded(
                  child: Text(
                    workshop.description.isNotEmpty
                        ? workshop.description
                        : 'Sin descripción disponible',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.small,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4EF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF9B3D24)),
          const SizedBox(width: 3),
          Text(
            label,
            style: AppTextStyles.small.copyWith(
              color: const Color(0xFF5F554E),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
