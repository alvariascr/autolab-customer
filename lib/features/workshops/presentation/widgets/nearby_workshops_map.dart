import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/location/current_location.dart';
import '../../domain/entities/workshop.dart';

class NearbyWorkshopsMap extends StatefulWidget {
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
  State<NearbyWorkshopsMap> createState() => _NearbyWorkshopsMapState();
}

class _NearbyWorkshopsMapState extends State<NearbyWorkshopsMap> {
  static const _initialZoom = 11.8;
  static const _minimumZoom = 5.0;
  static const _maximumZoom = 17.5;
  static const _zoomStep = 1.0;

  late final MapController _mapController;
  double _currentZoom = _initialZoom;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  void _zoomIn() => _updateZoom(_currentZoom + _zoomStep);

  void _zoomOut() => _updateZoom(_currentZoom - _zoomStep);

  void _updateZoom(double nextZoom) {
    final location = widget.currentLocation;
    if (location == null) {
      return;
    }

    final safeZoom = nextZoom.clamp(_minimumZoom, _maximumZoom);
    final center = LatLng(location.latitude, location.longitude);

    setState(() {
      _currentZoom = safeZoom;
    });
    _mapController.move(center, safeZoom);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentLocation == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            widget.emptyMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6B5F57)),
          ),
        ),
      );
    }

    final center = LatLng(
      widget.currentLocation!.latitude,
      widget.currentLocation!.longitude,
    );
    final markers = <Marker>[
      Marker(
        point: center,
        width: 42,
        height: 42,
        child: const _CurrentLocationMarker(),
      ),
      ...widget.workshops.map(
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
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: _initialZoom,
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
          Positioned(
            right: 12,
            bottom: 28,
            child: _ZoomControls(onZoomIn: _zoomIn, onZoomOut: _zoomOut),
          ),
          if (widget.workshops.isEmpty)
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
                    widget.emptyMessage,
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

class _ZoomControls extends StatelessWidget {
  const _ZoomControls({required this.onZoomIn, required this.onZoomOut});

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: const ValueKey('map-zoom-in-button'),
            tooltip: 'Acercar',
            onPressed: onZoomIn,
            icon: const Icon(Icons.add),
          ),
          Container(width: 32, height: 1, color: const Color(0xFFE9DDD2)),
          IconButton(
            key: const ValueKey('map-zoom-out-button'),
            tooltip: 'Alejar',
            onPressed: onZoomOut,
            icon: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }
}
