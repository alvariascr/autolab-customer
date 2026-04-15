import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/location/current_location.dart';
import '../../domain/entities/workshop.dart';

class NearbyWorkshopsMap extends StatelessWidget {
  const NearbyWorkshopsMap({
    super.key,
    required this.workshops,
    required this.currentLocation,
    required this.emptyMessage,
  });

  final List<Workshop> workshops;
  final CurrentLocation? currentLocation;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (currentLocation == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6B5F57)),
          ),
        ),
      );
    }

    final center = LatLng(
      currentLocation!.latitude,
      currentLocation!.longitude,
    );
    final markers = <Marker>[
      Marker(
        point: center,
        width: 42,
        height: 42,
        child: const _CurrentLocationMarker(),
      ),
      ...workshops.map(
        (workshop) => Marker(
          point: LatLng(workshop.latitude, workshop.longitude),
          width: 52,
          height: 52,
          child: _WorkshopMarker(workshop: workshop),
        ),
      ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 11.8,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.autolab.customer',
              ),
              MarkerLayer(markers: markers),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: null,
                  ),
                ],
              ),
            ],
          ),
          if (workshops.isEmpty)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Text(
                    emptyMessage,
                    key: const ValueKey('nearby-workshops-empty-message'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF6B5F57),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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

class _WorkshopMarker extends StatelessWidget {
  const _WorkshopMarker({required this.workshop});

  final Workshop workshop;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: workshop.name,
      child: Container(
        key: ValueKey('workshop-marker-${workshop.id}'),
        decoration: BoxDecoration(
          color: const Color(0xFF9B3D24),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.location_on, color: Colors.white),
      ),
    );
  }
}

class _CurrentLocationMarker extends StatelessWidget {
  const _CurrentLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('current-location-marker'),
      decoration: BoxDecoration(
        color: const Color(0xFF181411),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: const Icon(Icons.my_location, size: 18, color: Colors.white),
    );
  }
}
