import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/location/current_location.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/workshop.dart';
import '../../domain/services/workshop_distance_calculator.dart';

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
  static const _initialZoom = 13.8;
  static const _minimumZoom = 5.0;
  static const _maximumZoom = 17.5;
  static const _zoomStep = 1.0;

  GoogleMapController? _mapController;
  double _currentZoom = _initialZoom;
  Workshop? _selectedWorkshop;
  bool _expandedSheet = false;
  bool _isMapLoading = true;

  @override
  void initState() {
    super.initState();
    _syncSelectedWorkshop();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitToMarkers());
  }

  @override
  void didUpdateWidget(covariant NearbyWorkshopsMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workshops != widget.workshops ||
        oldWidget.currentLocation != widget.currentLocation) {
      _resetMapFeedbackState();
      _syncSelectedWorkshop();
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitToMarkers());
    }
  }

  void _resetMapFeedbackState() {
    _isMapLoading = true;
  }

  void _syncSelectedWorkshop() {
    if (widget.workshops.isEmpty || widget.currentLocation == null) {
      _selectedWorkshop = null;
      _expandedSheet = false;
      return;
    }

    if (_selectedWorkshop != null &&
        widget.workshops.any(
          (workshop) => workshop.id == _selectedWorkshop!.id,
        )) {
      return;
    }

    final location = widget.currentLocation!;
    final sorted = [...widget.workshops]
      ..sort(
        (a, b) =>
            WorkshopDistanceCalculator.distanceInKm(
              currentLocation: location,
              workshop: a,
            ).compareTo(
              WorkshopDistanceCalculator.distanceInKm(
                currentLocation: location,
                workshop: b,
              ),
            ),
      );

    _selectedWorkshop = sorted.first;
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
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: center, zoom: safeZoom),
      ),
    );
  }

  void _fitToMarkers() {
    final location = widget.currentLocation;
    if (!mounted || location == null || widget.workshops.isEmpty) {
      return;
    }

    final maxDistanceKm = widget.workshops
        .map(
          (workshop) => WorkshopDistanceCalculator.distanceInKm(
            currentLocation: location,
            workshop: workshop,
          ),
        )
        .fold<double>(0, (currentMax, distance) {
          return distance > currentMax ? distance : currentMax;
        });

    if (maxDistanceKm <= 0.8) {
      final focusWorkshop = _selectedWorkshop ?? widget.workshops.first;
      final focusPoint = LatLng(
        focusWorkshop.latitude,
        focusWorkshop.longitude,
      );
      _currentZoom = 16.4;
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: focusPoint, zoom: _currentZoom),
        ),
      );
      return;
    }

    if (maxDistanceKm <= 1.6) {
      final focusWorkshop = _selectedWorkshop ?? widget.workshops.first;
      final focusPoint = LatLng(
        focusWorkshop.latitude,
        focusWorkshop.longitude,
      );
      _currentZoom = 15.4;
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: focusPoint, zoom: _currentZoom),
        ),
      );
      return;
    }

    final points = <LatLng>[
      LatLng(location.latitude, location.longitude),
      ...widget.workshops.map(
        (workshop) => LatLng(workshop.latitude, workshop.longitude),
      ),
    ];
    final bounds = _boundsFrom(points);

    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 72));
  }

  void _selectWorkshop(Workshop workshop) {
    setState(() {
      _selectedWorkshop = workshop;
      _expandedSheet = false;
    });

    final zoom = _currentZoom < 16 ? 16.0 : _currentZoom;
    _currentZoom = zoom;
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(workshop.latitude, workshop.longitude),
          zoom: zoom,
        ),
      ),
    );
  }

  void _toggleSheet() {
    if (_selectedWorkshop == null) {
      return;
    }

    setState(() {
      _expandedSheet = !_expandedSheet;
    });
  }

  void _handleMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _fitToMarkers();
    if (!mounted) {
      return;
    }

    setState(() {
      _isMapLoading = false;
    });
  }

  LatLngBounds _boundsFrom(List<LatLng> points) {
    var minLatitude = points.first.latitude;
    var maxLatitude = points.first.latitude;
    var minLongitude = points.first.longitude;
    var maxLongitude = points.first.longitude;

    for (final point in points.skip(1)) {
      if (point.latitude < minLatitude) {
        minLatitude = point.latitude;
      }
      if (point.latitude > maxLatitude) {
        maxLatitude = point.latitude;
      }
      if (point.longitude < minLongitude) {
        minLongitude = point.longitude;
      }
      if (point.longitude > maxLongitude) {
        maxLongitude = point.longitude;
      }
    }

    return LatLngBounds(
      southwest: LatLng(minLatitude, minLongitude),
      northeast: LatLng(maxLatitude, maxLongitude),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('current-location'),
        position: center,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(title: l10n.mapYourLocation),
      ),
      ...widget.workshops.map(
        (workshop) => Marker(
          markerId: MarkerId('workshop-${workshop.id}'),
          position: LatLng(workshop.latitude, workshop.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _selectedWorkshop?.id == workshop.id
                ? BitmapDescriptor.hueOrange
                : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: workshop.name,
            snippet: workshop.locationAddress.isEmpty
                ? null
                : workshop.locationAddress,
          ),
          onTap: () => _selectWorkshop(workshop),
        ),
      ),
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        children: [
          GoogleMap(
            key: const ValueKey('nearby-google-map'),
            initialCameraPosition: CameraPosition(
              target: center,
              zoom: _initialZoom,
            ),
            markers: markers,
            onMapCreated: _handleMapCreated,
            onCameraMove: (position) => _currentZoom = position.zoom,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            padding: const EdgeInsets.fromLTRB(0, 56, 0, 150),
          ),
          Positioned(
            right: 14,
            top: 78,
            child: _ZoomControls(
              onZoomIn: _zoomIn,
              onZoomOut: _zoomOut,
              l10n: l10n,
            ),
          ),
          Positioned(
            left: 14,
            bottom: 18,
            child: IgnorePointer(
              child: _MapFloatingBadge(
                icon: Icons.my_location_rounded,
                label: l10n.mapYourLocation,
              ),
            ),
          ),
          if (widget.workshops.isEmpty)
            Positioned(
              top: 56,
              left: 16,
              right: 16,
              child: _EmptyMapCard(message: widget.emptyMessage),
            ),
          if (_isMapLoading)
            Positioned(
              top: 56,
              left: 16,
              right: 16,
              child: _MapStatusCard(
                icon: Icons.map_outlined,
                title: l10n.mapLoadingTitle,
                message: l10n.mapLoadingMessage,
              ),
            ),
          if (_selectedWorkshop != null && widget.workshops.isNotEmpty)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: _SelectedWorkshopSheet(
                workshop: _selectedWorkshop!,
                currentLocation: widget.currentLocation!,
                expanded: _expandedSheet,
                onTap: _toggleSheet,
                l10n: l10n,
              ),
            ),
        ],
      ),
    );
  }
}

class _SelectedWorkshopSheet extends StatelessWidget {
  const _SelectedWorkshopSheet({
    required this.workshop,
    required this.currentLocation,
    required this.expanded,
    required this.onTap,
    required this.l10n,
  });

  final Workshop workshop;
  final CurrentLocation currentLocation;
  final bool expanded;
  final VoidCallback onTap;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final distance = WorkshopDistanceCalculator.distanceInKm(
      currentLocation: currentLocation,
      workshop: workshop,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 22,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6D7CA),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _WorkshopCoverThumb(workshop: workshop),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workshop.name,
                          maxLines: expanded ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF181411),
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _MapInfoChip(
                              icon: Icons.near_me_outlined,
                              label: l10n.mapInfoDistancePrefix(
                                WorkshopDistanceCalculator.formatKm(distance),
                              ),
                            ),
                            _MapInfoChip(
                              icon: Icons.local_shipping_outlined,
                              label: l10n.mapInfoCoveragePrefix(
                                WorkshopDistanceCalculator.formatKm(
                                  workshop.deliveryRadiusKm,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                    color: const Color(0xFF6B5F57),
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  workshop.locationAddress.isNotEmpty
                      ? workshop.locationAddress
                      : l10n.mapSheetFallbackAddress,
                  maxLines: expanded ? 3 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6B5F57),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
              AnimatedCrossFade(
                crossFadeState: expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 220),
                firstChild: const SizedBox(height: 0),
                secondChild: Column(
                  children: [
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFF0E2D6)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _DetailStat(
                            label: l10n.mapSheetLabelWorkshop,
                            value: workshop.name,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DetailStat(
                            label: l10n.mapSheetLabelCoverage,
                            value: WorkshopDistanceCalculator.formatKm(
                              workshop.deliveryRadiusKm,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        workshop.description.isNotEmpty
                            ? workshop.description
                            : l10n.mapSheetFallbackDescription,
                        style: const TextStyle(
                          color: Color(0xFF5F554E),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkshopCoverThumb extends StatelessWidget {
  const _WorkshopCoverThumb({required this.workshop});

  final Workshop workshop;

  @override
  Widget build(BuildContext context) {
    final imageUrl = workshop.coverUrl.isNotEmpty
        ? workshop.coverUrl
        : workshop.avatarUrl;

    final fallback = Container(
      width: 82,
      height: 82,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF102A56), Color(0xFF1E4D8F), Color(0xFFEF9C23)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.build_rounded, color: Colors.white, size: 28),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: imageUrl.isEmpty
          ? fallback
          : Image.network(
              imageUrl,
              width: 82,
              height: 82,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => fallback,
            ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  const _DetailStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4EF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8A7C72),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF181411),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoomControls extends StatelessWidget {
  const _ZoomControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.l10n,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: const ValueKey('map-zoom-in-button'),
            tooltip: l10n.mapZoomInTooltip,
            onPressed: onZoomIn,
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.add, size: 22),
          ),
          Container(width: 36, height: 1, color: const Color(0xFFE9DDD2)),
          IconButton(
            key: const ValueKey('map-zoom-out-button'),
            tooltip: l10n.mapZoomOutTooltip,
            onPressed: onZoomOut,
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.remove, size: 22),
          ),
        ],
      ),
    );
  }
}

class _MapInfoChip extends StatelessWidget {
  const _MapInfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4EF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF9B3D24)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF5F554E),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapFloatingBadge extends StatelessWidget {
  const _MapFloatingBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF181411)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF181411),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapStatusCard extends StatelessWidget {
  const _MapStatusCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F4EF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF181411), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF181411),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Color(0xFF6B5F57),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMapCard extends StatelessWidget {
  const _EmptyMapCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('nearby-workshops-empty-message'),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF6B5F57),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}
