import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/location/current_location.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../products/domain/services/workshop_product_search_grouper.dart';
import '../../domain/entities/workshop.dart';
import '../../domain/services/workshop_distance_calculator.dart';

class NearbyWorkshopsMap extends StatefulWidget {
  const NearbyWorkshopsMap({
    super.key,
    required this.workshops,
    required this.currentLocation,
    required this.emptyMessage,
    this.query = '',
    this.productResults = const [],
    this.isLoadingProductResults = false,
  });

  final List<Workshop> workshops;
  final CurrentLocation? currentLocation;
  final String emptyMessage;
  final String query;
  final List<WorkshopProductSearchResult> productResults;
  final bool isLoadingProductResults;

  @override
  State<NearbyWorkshopsMap> createState() => _NearbyWorkshopsMapState();
}

class _NearbyWorkshopsMapState extends State<NearbyWorkshopsMap> {
  static const _initialZoom = 13.8;
  static const _minimumZoom = 5.0;
  static const _maximumZoom = 17.5;
  static const _zoomStep = 1.0;
  static const _markerPixelRatio = 3.0;
  static const _mapStyle = '''
[
  {
    "featureType": "poi.business",
    "stylers": [{ "visibility": "off" }]
  },
  {
    "featureType": "poi.medical",
    "stylers": [{ "visibility": "off" }]
  },
  {
    "featureType": "transit",
    "stylers": [{ "visibility": "off" }]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{ "color": "#E8EEF3" }]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [{ "color": "#66727A" }]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{ "color": "#D7E7F4" }]
  },
  {
    "featureType": "landscape",
    "elementType": "geometry",
    "stylers": [{ "color": "#F8F4EF" }]
  }
]
''';

  GoogleMapController? _mapController;
  BitmapDescriptor? _currentLocationIcon;
  BitmapDescriptor? _workshopIcon;
  BitmapDescriptor? _selectedWorkshopIcon;
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
    _loadMarkerIcons();
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

  void _openWorkshopProfile(Workshop workshop) {
    context.push('/workshops/${workshop.id}');
  }

  void _openWorkshopProducts(WorkshopProductSearchResult result) {
    context.push(
      '/search/workshops/${result.workshop.id}/products?query=${Uri.encodeComponent(widget.query)}',
    );
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

  Future<void> _loadMarkerIcons() async {
    if (_currentLocationIcon != null &&
        _workshopIcon != null &&
        _selectedWorkshopIcon != null) {
      return;
    }

    final icons = await Future.wait([
      _createCurrentLocationIcon(),
      _createWorkshopPinIcon(isSelected: false),
      _createWorkshopPinIcon(isSelected: true),
    ]);

    if (!mounted) {
      return;
    }

    setState(() {
      _currentLocationIcon = icons[0];
      _workshopIcon = icons[1];
      _selectedWorkshopIcon = icons[2];
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

  Future<BitmapDescriptor> _createCurrentLocationIcon() async {
    const size = Size(56, 56);
    final bytes = await _drawMarkerBytes(size, (canvas) {
      const center = Offset(28, 28);

      canvas.drawCircle(
        center,
        22,
        Paint()..color = const Color(0xFF181411).withValues(alpha: 0.18),
      );
      canvas.drawCircle(center, 12, Paint()..color = Colors.white);
      canvas.drawCircle(center, 8, Paint()..color = const Color(0xFF181411));
    });

    return BitmapDescriptor.bytes(
      bytes,
      imagePixelRatio: _markerPixelRatio,
      width: size.width,
      height: size.height,
    );
  }

  Future<BitmapDescriptor> _createWorkshopPinIcon({
    required bool isSelected,
  }) async {
    final size = isSelected ? const Size(78, 92) : const Size(68, 82);
    final primary = isSelected
        ? const Color(0xFFE94A3F)
        : const Color(0xFFC24E2C);
    final secondary = isSelected
        ? const Color(0xFF9B3D24)
        : const Color(0xFF7F2F1A);
    final centerX = size.width / 2;

    final bytes = await _drawMarkerBytes(size, (canvas) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(centerX, size.height - 8),
          width: isSelected ? 34 : 28,
          height: 10,
        ),
        Paint()..color = const Color(0x33000000),
      );

      final pinPath = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              isSelected ? 9 : 8,
              6,
              isSelected ? 60 : 52,
              isSelected ? 60 : 52,
            ),
            Radius.circular(isSelected ? 22 : 20),
          ),
        )
        ..moveTo(centerX - 13, isSelected ? 56 : 50)
        ..quadraticBezierTo(
          centerX,
          size.height - 8,
          centerX + 13,
          isSelected ? 56 : 50,
        )
        ..close();

      canvas.drawPath(
        pinPath.shift(const Offset(0, 3)),
        Paint()..color = const Color(0x26000000),
      );
      canvas.drawPath(
        pinPath,
        Paint()
          ..shader = ui.Gradient.linear(
            const Offset(0, 6),
            Offset(0, size.height - 12),
            [primary, secondary],
          ),
      );
      canvas.drawPath(
        pinPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 4 : 3
          ..color = Colors.white,
      );

      final badgeRadius = isSelected ? 19.0 : 16.5;
      canvas.drawCircle(
        Offset(centerX, isSelected ? 36 : 32),
        badgeRadius,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        Offset(centerX, isSelected ? 36 : 32),
        badgeRadius - 4,
        Paint()..color = const Color(0xFFF8F4EF),
      );

      _paintMarkerGlyph(
        canvas,
        text: 'A',
        center: Offset(centerX, isSelected ? 35 : 31),
        fontSize: isSelected ? 24 : 20,
        color: const Color(0xFF181411),
      );
    });

    return BitmapDescriptor.bytes(
      bytes,
      imagePixelRatio: _markerPixelRatio,
      width: size.width,
      height: size.height,
    );
  }

  Future<Uint8List> _drawMarkerBytes(
    Size logicalSize,
    void Function(Canvas canvas) paint,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(_markerPixelRatio);

    paint(canvas);

    final image = await recorder.endRecording().toImage(
      (logicalSize.width * _markerPixelRatio).round(),
      (logicalSize.height * _markerPixelRatio).round(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  void _paintMarkerGlyph(
    Canvas canvas, {
    required String text,
    required Offset center,
    required double fontSize,
    required Color color,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
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
        icon:
            _currentLocationIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(title: l10n.mapYourLocation),
      ),
      ...widget.workshops.map(
        (workshop) => Marker(
          markerId: MarkerId('workshop-${workshop.id}'),
          position: LatLng(workshop.latitude, workshop.longitude),
          icon: _selectedWorkshop?.id == workshop.id
              ? _selectedWorkshopIcon ??
                    BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueOrange,
                    )
              : _workshopIcon ??
                    BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed,
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

    return ClipRect(
      child: Stack(
        children: [
          GoogleMap(
            key: const ValueKey('nearby-google-map'),
            initialCameraPosition: CameraPosition(
              target: center,
              zoom: _initialZoom,
            ),
            style: _mapStyle,
            markers: markers,
            onMapCreated: _handleMapCreated,
            onCameraMove: (position) => _currentZoom = position.zoom,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            padding: const EdgeInsets.fromLTRB(0, 158, 0, 240),
          ),
          Positioned(
            right: 14,
            top: 192,
            child: _ZoomControls(
              onZoomIn: _zoomIn,
              onZoomOut: _zoomOut,
              l10n: l10n,
            ),
          ),
          Positioned(
            right: 14,
            top: 304,
            child: IgnorePointer(
              child: _MapFloatingBadge(
                icon: Icons.my_location_rounded,
                tooltip: l10n.mapYourLocation,
              ),
            ),
          ),
          if (widget.workshops.isEmpty)
            Positioned(
              top: 170,
              left: 16,
              right: 16,
              child: _EmptyMapCard(message: widget.emptyMessage),
            ),
          if (_isMapLoading)
            Positioned(
              top: 170,
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
              left: 0,
              right: 0,
              bottom: 86,
              child: _SelectedWorkshopSheet(
                workshop: _selectedWorkshop!,
                currentLocation: widget.currentLocation!,
                expanded: _expandedSheet,
                results: widget.workshops,
                query: widget.query,
                productResults: widget.productResults,
                isLoadingProductResults: widget.isLoadingProductResults,
                onTap: _toggleSheet,
                onWorkshopSelected: _selectWorkshop,
                onWorkshopOpened: _openWorkshopProfile,
                onProductResultOpened: _openWorkshopProducts,
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
    required this.results,
    required this.query,
    required this.productResults,
    required this.isLoadingProductResults,
    required this.onTap,
    required this.onWorkshopSelected,
    required this.onWorkshopOpened,
    required this.onProductResultOpened,
    required this.l10n,
  });

  final Workshop workshop;
  final CurrentLocation currentLocation;
  final bool expanded;
  final List<Workshop> results;
  final String query;
  final List<WorkshopProductSearchResult> productResults;
  final bool isLoadingProductResults;
  final VoidCallback onTap;
  final ValueChanged<Workshop> onWorkshopSelected;
  final ValueChanged<Workshop> onWorkshopOpened;
  final ValueChanged<WorkshopProductSearchResult> onProductResultOpened;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final distance = WorkshopDistanceCalculator.distanceInKm(
      currentLocation: currentLocation,
      workshop: workshop,
    );

    final shouldShowResults = query.trim().isNotEmpty;
    final productWorkshopIds = productResults
        .map((result) => result.workshop.id)
        .toSet();
    final workshopResults = shouldShowResults
        ? results
              .where((workshop) => !productWorkshopIds.contains(workshop.id))
              .toList(growable: false)
        : results;
    final resultsCount = productResults.length + workshopResults.length;

    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.98),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 28,
              offset: Offset(0, -8),
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
            if (shouldShowResults)
              _SearchResultsHeader(count: resultsCount, query: query)
            else
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Talleres cerca de ti',
                  style: TextStyle(
                    color: Color(0xFF181411),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            const SizedBox(height: 14),
            if (shouldShowResults)
              _WorkshopResultsList(
                workshops: workshopResults,
                productResults: productResults,
                isLoadingProductResults: isLoadingProductResults,
                query: query,
                currentLocation: currentLocation,
                onSelected: onWorkshopSelected,
                onOpened: onWorkshopOpened,
                onProductResultOpened: onProductResultOpened,
                l10n: l10n,
              )
            else
              InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(22),
                child: _SelectedWorkshopSummary(
                  workshop: workshop,
                  currentLocation: currentLocation,
                  expanded: expanded,
                  distance: distance,
                  l10n: l10n,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultsHeader extends StatelessWidget {
  const _SearchResultsHeader({required this.count, required this.query});

  final int count;
  final String query;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        count == 1 ? '1 resultado' : '$count resultados',
        style: const TextStyle(
          color: Color(0xFF181411),
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SelectedWorkshopSummary extends StatelessWidget {
  const _SelectedWorkshopSummary({
    required this.workshop,
    required this.currentLocation,
    required this.expanded,
    required this.distance,
    required this.l10n,
  });

  final Workshop workshop;
  final CurrentLocation currentLocation;
  final bool expanded;
  final double distance;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
    );
  }
}

class _WorkshopResultsList extends StatelessWidget {
  const _WorkshopResultsList({
    required this.workshops,
    required this.productResults,
    required this.isLoadingProductResults,
    required this.query,
    required this.currentLocation,
    required this.onSelected,
    required this.onOpened,
    required this.onProductResultOpened,
    required this.l10n,
  });

  final List<Workshop> workshops;
  final List<WorkshopProductSearchResult> productResults;
  final bool isLoadingProductResults;
  final String query;
  final CurrentLocation currentLocation;
  final ValueChanged<Workshop> onSelected;
  final ValueChanged<Workshop> onOpened;
  final ValueChanged<WorkshopProductSearchResult> onProductResultOpened;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (isLoadingProductResults &&
        productResults.isEmpty &&
        workshops.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 18),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (productResults.isEmpty && workshops.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 18),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'No encontramos talleres para esa búsqueda.',
            style: TextStyle(
              color: Color(0xFF6B5F57),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 330),
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 8),
        shrinkWrap: true,
        itemCount: productResults.length + workshops.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index < productResults.length) {
            final result = productResults[index];

            return _WorkshopProductResultTile(
              result: result,
              query: query,
              currentLocation: currentLocation,
              onSelected: () => onSelected(result.workshop),
              onOpened: () => onProductResultOpened(result),
              l10n: l10n,
            );
          }

          final workshopIndex = index - productResults.length;
          final workshop = workshops[workshopIndex];

          return _WorkshopResultTile(
            workshop: workshop,
            currentLocation: currentLocation,
            onSelected: () => onSelected(workshop),
            onOpened: () => onOpened(workshop),
            l10n: l10n,
          );
        },
      ),
    );
  }
}

class _WorkshopProductResultTile extends StatelessWidget {
  const _WorkshopProductResultTile({
    required this.result,
    required this.query,
    required this.currentLocation,
    required this.onSelected,
    required this.onOpened,
    required this.l10n,
  });

  final WorkshopProductSearchResult result;
  final String query;
  final CurrentLocation currentLocation;
  final VoidCallback onSelected;
  final VoidCallback onOpened;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final workshop = result.workshop;
    final distance = WorkshopDistanceCalculator.distanceInKm(
      currentLocation: currentLocation,
      workshop: workshop,
    );
    final previewProducts = result.products.take(3).toList(growable: false);

    return Material(
      color: const Color(0xFFFFF8ED),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onOpened,
        onLongPress: onSelected,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _WorkshopCoverThumb(workshop: workshop),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workshop.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF181411),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${result.count} resultado${result.count == 1 ? '' : 's'} para "$query"',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF6B5F57),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _MapInfoChip(
                              icon: Icons.inventory_2_outlined,
                              label: 'Productos',
                            ),
                            _MapInfoChip(
                              icon: Icons.near_me_outlined,
                              label: l10n.mapInfoDistancePrefix(
                                WorkshopDistanceCalculator.formatKm(distance),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Ver en mapa',
                    onPressed: onSelected,
                    icon: const Icon(
                      Icons.location_searching_rounded,
                      color: Color(0xFF181411),
                    ),
                  ),
                ],
              ),
              if (previewProducts.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final product in previewProducts)
                      _ProductMatchChip(label: product.name),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductMatchChip extends StatelessWidget {
  const _ProductMatchChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFF0E2D6)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF181411),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _WorkshopResultTile extends StatelessWidget {
  const _WorkshopResultTile({
    required this.workshop,
    required this.currentLocation,
    required this.onSelected,
    required this.onOpened,
    required this.l10n,
  });

  final Workshop workshop;
  final CurrentLocation currentLocation;
  final VoidCallback onSelected;
  final VoidCallback onOpened;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final distance = WorkshopDistanceCalculator.distanceInKm(
      currentLocation: currentLocation,
      workshop: workshop,
    );

    return Material(
      color: const Color(0xFFFBFAF8),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onOpened,
        onLongPress: onSelected,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              _WorkshopCoverThumb(workshop: workshop),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workshop.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF181411),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      workshop.locationAddress.isNotEmpty
                          ? workshop.locationAddress
                          : l10n.mapSheetFallbackAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6B5F57),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
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
              IconButton(
                tooltip: 'Ver en mapa',
                onPressed: onSelected,
                icon: const Icon(
                  Icons.location_searching_rounded,
                  color: Color(0xFF181411),
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
  const _MapFloatingBadge({required this.icon, required this.tooltip});

  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: SizedBox(
          width: 50,
          height: 50,
          child: Icon(icon, size: 22, color: const Color(0xFF181411)),
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
