import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/location/current_location.dart';
import '../../../../core/theme/autolab_customer.dart';
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
  static const _mapLoadingTimeout = Duration(seconds: 6);
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
  static const _darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{ "color": "#121212" }]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{ "color": "#E8E0E0" }]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{ "color": "#121212" }]
  },
  {
    "featureType": "poi",
    "stylers": [{ "visibility": "off" }]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{ "color": "#252525" }]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [{ "color": "#A9A9A9" }]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{ "color": "#050606" }]
  }
]
''';

  GoogleMapController? _mapController;
  BitmapDescriptor? _currentLocationIcon;
  BitmapDescriptor? _workshopIcon;
  BitmapDescriptor? _selectedWorkshopIcon;
  double _currentZoom = _initialZoom;
  Workshop? _selectedWorkshop;
  List<Workshop> _visibleWorkshops = const [];
  bool _expandedSheet = false;
  bool _isMapLoading = true;
  bool _hasMapLoadTimedOut = false;
  Timer? _mapLoadingTimer;

  @override
  void initState() {
    super.initState();
    _syncSelectedWorkshop();
    _startMapLoadingTimeout();
    unawaited(_loadMarkerIcons());
  }

  @override
  void dispose() {
    _mapLoadingTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant NearbyWorkshopsMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workshops != widget.workshops ||
        oldWidget.currentLocation != widget.currentLocation) {
      _syncSelectedWorkshop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _syncVisibleWorkshopsWithMap();
      });
    }
  }

  void _startMapLoadingTimeout() {
    _mapLoadingTimer?.cancel();
    _mapLoadingTimer = Timer(_mapLoadingTimeout, () {
      if (!mounted || !_isMapLoading) {
        return;
      }

      setState(() {
        _hasMapLoadTimedOut = true;
      });
    });
  }

  void _syncSelectedWorkshop() {
    if (widget.workshops.isEmpty || widget.currentLocation == null) {
      _selectedWorkshop = null;
      _visibleWorkshops = const [];
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

  Future<void> _syncVisibleWorkshopsWithMap() async {
    final controller = _mapController;
    if (!mounted || controller == null || widget.workshops.isEmpty) {
      return;
    }

    final bounds = await controller.getVisibleRegion();
    if (!mounted) {
      return;
    }

    final visibleWorkshops = widget.workshops
        .where((workshop) => _boundsContain(bounds, workshop))
        .toList(growable: false);

    final selectedIsVisible =
        _selectedWorkshop != null &&
        visibleWorkshops.any(
          (workshop) => workshop.id == _selectedWorkshop!.id,
        );

    setState(() {
      _visibleWorkshops = visibleWorkshops;
      if (!selectedIsVisible && visibleWorkshops.isNotEmpty) {
        _selectedWorkshop = visibleWorkshops.first;
      }
    });
  }

  void _zoomIn() => _updateZoom(_currentZoom + _zoomStep);

  void _zoomOut() => _updateZoom(_currentZoom - _zoomStep);

  void _centerOnCurrentLocation() {
    final location = widget.currentLocation;
    if (location == null) {
      return;
    }

    final zoom = _currentZoom < _initialZoom ? _initialZoom : _currentZoom;
    _currentZoom = zoom;
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(location.latitude, location.longitude),
          zoom: zoom,
        ),
      ),
    );
  }

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
    _mapLoadingTimer?.cancel();
    _mapController = controller;
    if (!mounted) {
      return;
    }

    setState(() {
      _isMapLoading = false;
      _hasMapLoadTimedOut = false;
    });
    unawaited(_syncVisibleWorkshopsWithMap());
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

  Future<BitmapDescriptor> _createCurrentLocationIcon() async {
    const size = Size(56, 56);
    final bytes = await _drawMarkerBytes(size, (canvas) {
      const center = Offset(28, 28);

      canvas.drawCircle(
        center,
        22,
        Paint()
          ..color = AutolabCustomer.customerLightText.withValues(alpha: 0.18),
      );
      canvas.drawCircle(center, 12, Paint()..color = AutolabCustomer.white);
      canvas.drawCircle(
        center,
        8,
        Paint()..color = AutolabCustomer.customerLightText,
      );
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
        ? AutolabCustomer.primary
        : AutolabCustomer.primary.withValues(alpha: 0.82);
    final secondary = isSelected
        ? AutolabCustomer.error
        : AutolabCustomer.error.withValues(alpha: 0.78);
    final centerX = size.width / 2;

    final bytes = await _drawMarkerBytes(size, (canvas) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(centerX, size.height - 8),
          width: isSelected ? 34 : 28,
          height: 10,
        ),
        Paint()..color = AutolabCustomer.secondary.withValues(alpha: 0.2),
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
        Paint()..color = AutolabCustomer.secondary.withValues(alpha: 0.15),
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
          ..color = AutolabCustomer.white,
      );

      final badgeRadius = isSelected ? 19.0 : 16.5;
      canvas.drawCircle(
        Offset(centerX, isSelected ? 36 : 32),
        badgeRadius,
        Paint()..color = AutolabCustomer.white,
      );
      canvas.drawCircle(
        Offset(centerX, isSelected ? 36 : 32),
        badgeRadius - 4,
        Paint()..color = AutolabCustomer.customerLightSoftSurface,
      );

      _paintMarkerGlyph(
        canvas,
        text: 'A',
        center: Offset(centerX, isSelected ? 35 : 31),
        fontSize: isSelected ? 24 : 20,
        color: AutolabCustomer.customerLightText,
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
            style: AutolabCustomer.body.copyWith(
              color: AutolabCustomer.customerSecondaryTextColor(context),
            ),
          ),
        ),
      );
    }

    final center = LatLng(
      widget.currentLocation!.latitude,
      widget.currentLocation!.longitude,
    );
    final sheetBottomOffset = AutolabCustomer.responsiveDouble(
      context,
      compact: 76,
      regular: 82,
      tablet: 94,
    );
    final sheetReservedHeight = _sheetReservedHeight(context);
    final safeTop = MediaQuery.paddingOf(context).top;
    final mapTopPadding =
        safeTop +
        AutolabCustomer.responsiveDouble(
          context,
          compact: 146,
          regular: 158,
          tablet: 172,
        );
    final zoomControlsTop =
        safeTop +
        AutolabCustomer.responsiveDouble(
          context,
          compact: 182,
          regular: 194,
          tablet: 216,
        );
    final locationControlTop =
        safeTop +
        AutolabCustomer.responsiveDouble(
          context,
          compact: 286,
          regular: 304,
          tablet: 336,
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
            style: AutolabCustomer.isDark(context) ? _darkMapStyle : _mapStyle,
            markers: markers,
            onMapCreated: _handleMapCreated,
            onCameraMove: (position) => _currentZoom = position.zoom,
            onCameraIdle: _syncVisibleWorkshopsWithMap,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            padding: EdgeInsets.fromLTRB(
              0,
              mapTopPadding,
              0,
              sheetBottomOffset + sheetReservedHeight,
            ),
          ),
          Positioned(
            right: AutolabCustomer.spacingMd,
            top: zoomControlsTop,
            child: _ZoomControls(
              onZoomIn: _zoomIn,
              onZoomOut: _zoomOut,
              l10n: l10n,
            ),
          ),
          Positioned(
            right: AutolabCustomer.spacingMd,
            top: locationControlTop,
            child: _MapFloatingButton(
              key: const ValueKey('map-current-location-button'),
              icon: Icons.my_location_rounded,
              tooltip: l10n.mapYourLocation,
              onPressed: _centerOnCurrentLocation,
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
                icon: _hasMapLoadTimedOut
                    ? Icons.warning_amber_rounded
                    : Icons.map_outlined,
                title: _hasMapLoadTimedOut
                    ? l10n.mapLoadingTimeoutTitle
                    : l10n.mapLoadingTitle,
                message: _hasMapLoadTimedOut
                    ? l10n.mapLoadingTimeoutMessage
                    : l10n.mapLoadingMessage,
              ),
            ),
          if (_selectedWorkshop != null && widget.workshops.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: sheetBottomOffset,
              child: _SelectedWorkshopSheet(
                workshop: _selectedWorkshop!,
                currentLocation: widget.currentLocation!,
                expanded: _expandedSheet,
                results: widget.query.trim().isEmpty
                    ? _visibleWorkshops
                    : widget.workshops,
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

  bool _boundsContain(LatLngBounds bounds, Workshop workshop) {
    final latitude = workshop.latitude;
    final longitude = workshop.longitude;
    final containsLatitude =
        latitude >= bounds.southwest.latitude &&
        latitude <= bounds.northeast.latitude;
    final containsLongitude =
        bounds.southwest.longitude <= bounds.northeast.longitude
        ? longitude >= bounds.southwest.longitude &&
              longitude <= bounds.northeast.longitude
        : longitude >= bounds.southwest.longitude ||
              longitude <= bounds.northeast.longitude;

    return containsLatitude && containsLongitude;
  }

  double _sheetReservedHeight(BuildContext context) {
    final hasSearchResults = widget.query.trim().isNotEmpty;
    final isExpanded = _expandedSheet || hasSearchResults;

    if (!isExpanded) {
      return AutolabCustomer.responsiveDouble(
        context,
        compact: 172,
        regular: 190,
        tablet: 220,
      );
    }

    return AutolabCustomer.responsiveDouble(
      context,
      compact: 372,
      regular: 420,
      tablet: 512,
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
    final shouldShowWorkshopList = shouldShowResults || expanded;
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
        padding: EdgeInsets.fromLTRB(
          AutolabCustomer.responsiveScreenMargin(context),
          AutolabCustomer.spacingSm,
          AutolabCustomer.responsiveScreenMargin(context),
          expanded ? AutolabCustomer.spacingMd : AutolabCustomer.spacingSmd,
        ),
        decoration: BoxDecoration(
          color: AutolabCustomer.customerElevatedSurfaceColor(
            context,
          ).withValues(alpha: 0.98),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AutolabCustomer.radiusLg),
          ),
          boxShadow: [
            BoxShadow(
              color: AutolabCustomer.secondary.withValues(alpha: 0.13),
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
                color: AutolabCustomer.customerBorderColor(context),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: AutolabCustomer.spacingSmd),
            if (shouldShowResults)
              _SearchResultsHeader(count: resultsCount, query: query)
            else if (expanded)
              InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AutolabCustomer.spacingXs,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.mapSheetNearbyWorkshopsTitle,
                          style: AutolabCustomer.h3.copyWith(
                            color: AutolabCustomer.customerTextColor(context),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AutolabCustomer.customerSecondaryTextColor(
                          context,
                        ),
                        size: AutolabCustomer.iconLg,
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(
              height: shouldShowWorkshopList
                  ? AutolabCustomer.spacingSmd
                  : AutolabCustomer.spacingXs,
            ),
            if (shouldShowWorkshopList)
              _WorkshopResultsList(
                workshops: workshopResults,
                productResults: shouldShowResults ? productResults : const [],
                isLoadingProductResults:
                    shouldShowResults && isLoadingProductResults,
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
                borderRadius: BorderRadius.circular(AutolabCustomer.radiusMd),
                child: _SelectedWorkshopSummary(
                  workshop: workshop,
                  currentLocation: currentLocation,
                  expanded: expanded,
                  distance: distance,
                  l10n: l10n,
                  onOpened: onWorkshopOpened,
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
    final l10n = AppLocalizations.of(context)!;

    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        count == 1 ? l10n.mapSheetOneResult : l10n.mapSheetResults(count),
        style: AutolabCustomer.h3.copyWith(
          color: AutolabCustomer.customerTextColor(context),
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
    required this.onOpened,
  });

  final Workshop workshop;
  final CurrentLocation currentLocation;
  final bool expanded;
  final double distance;
  final AppLocalizations l10n;
  final ValueChanged<Workshop> onOpened;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WorkshopCoverThumb(workshop: workshop, size: expanded ? 86 : 62),
            const SizedBox(width: AutolabCustomer.spacingSmd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workshop.name,
                    maxLines: expanded ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: AutolabCustomer.bodyLarge.copyWith(
                      color: AutolabCustomer.customerTextColor(context),
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  if (!expanded) ...[
                    const SizedBox(height: AutolabCustomer.spacingXs),
                    Text(
                      workshop.locationAddress.isNotEmpty
                          ? workshop.locationAddress
                          : l10n.mapSheetFallbackAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AutolabCustomer.caption.copyWith(
                        color: AutolabCustomer.customerSecondaryTextColor(
                          context,
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: AutolabCustomer.spacingSm),
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
            const SizedBox(width: AutolabCustomer.spacingSm),
            Icon(
              expanded
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.keyboard_arrow_up_rounded,
              color: AutolabCustomer.customerSecondaryTextColor(context),
              size: 24,
            ),
          ],
        ),
        AnimatedCrossFade(
          crossFadeState: expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
          firstChild: const SizedBox(height: 0),
          secondChild: Column(
            children: [
              const SizedBox(height: AutolabCustomer.spacingSmd),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  workshop.locationAddress.isNotEmpty
                      ? workshop.locationAddress
                      : l10n.mapSheetFallbackAddress,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AutolabCustomer.caption.copyWith(
                    color: AutolabCustomer.customerSecondaryTextColor(context),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: AutolabCustomer.spacingSmd),
              Divider(
                height: 1,
                color: AutolabCustomer.customerBorderColor(context),
              ),
              const SizedBox(height: AutolabCustomer.spacingSmd),
              Row(
                children: [
                  Expanded(
                    child: _DetailStat(
                      label: l10n.mapSheetLabelWorkshop,
                      value: workshop.name,
                    ),
                  ),
                  const SizedBox(width: AutolabCustomer.spacingSm),
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
              const SizedBox(height: AutolabCustomer.spacingSmd),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  workshop.description.isNotEmpty
                      ? workshop.description
                      : l10n.mapSheetFallbackDescription,
                  style: AutolabCustomer.caption.copyWith(
                    color: AutolabCustomer.customerSecondaryTextColor(context),
                    height: 1.5,
                  ),
                ),
              ),
              if (workshop.serviceCategories.isNotEmpty) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: workshop.serviceCategories
                        .take(3)
                        .map(
                          (category) => _MapInfoChip(
                            icon: Icons.handyman_outlined,
                            label: category,
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ],
              if (workshop.paymentMethods.isNotEmpty) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: workshop.paymentMethods
                        .take(2)
                        .map(
                          (method) => _MapInfoChip(
                            icon: Icons.payments_outlined,
                            label: method,
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton.icon(
                  onPressed: () => onOpened(workshop),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF181411),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.storefront_outlined, size: 18),
                  label: Text(
                    l10n.mapSheetOpenWorkshopAction,
                    style: const TextStyle(fontWeight: FontWeight.w800),
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
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            l10n.mapSheetNoSearchResults,
            style: AutolabCustomer.body.copyWith(
              color: AutolabCustomer.customerSecondaryTextColor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: AutolabCustomer.responsiveDouble(
          context,
          compact: 274,
          regular: 318,
          tablet: 396,
        ),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 8),
        shrinkWrap: true,
        itemCount: productResults.length + workshops.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AutolabCustomer.spacingSmd),
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
      color: AutolabCustomer.customerSoftSurfaceColor(context),
      borderRadius: BorderRadius.circular(AutolabCustomer.radiusMd),
      child: InkWell(
        onTap: onOpened,
        onLongPress: onSelected,
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AutolabCustomer.spacingSmd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _WorkshopCoverThumb(workshop: workshop),
                  const SizedBox(width: AutolabCustomer.spacingSmd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workshop.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AutolabCustomer.bodyLarge.copyWith(
                            color: AutolabCustomer.customerTextColor(context),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: AutolabCustomer.spacingXs),
                        Text(
                          l10n.mapSheetProductSearchResults(
                            result.count,
                            query,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AutolabCustomer.caption.copyWith(
                            color: AutolabCustomer.customerSecondaryTextColor(
                              context,
                            ),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AutolabCustomer.spacingSm),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _MapInfoChip(
                              icon: Icons.inventory_2_outlined,
                              label: l10n.mapSheetProductsLabel,
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
                    tooltip: l10n.mapSheetViewOnMapTooltip,
                    onPressed: onSelected,
                    icon: const Icon(
                      Icons.location_searching_rounded,
                      color: AutolabCustomer.primary,
                    ),
                  ),
                ],
              ),
              if (previewProducts.isNotEmpty) ...[
                const SizedBox(height: AutolabCustomer.spacingSm),
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
        color: AutolabCustomer.customerElevatedSurfaceColor(context),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AutolabCustomer.customerBorderColor(context)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AutolabCustomer.caption.copyWith(
          color: AutolabCustomer.customerTextColor(context),
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
      color: AutolabCustomer.customerElevatedSurfaceColor(context),
      borderRadius: BorderRadius.circular(AutolabCustomer.radiusMd),
      child: InkWell(
        onTap: onOpened,
        onLongPress: onSelected,
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AutolabCustomer.spacingSmd),
          child: Row(
            children: [
              _WorkshopCoverThumb(workshop: workshop),
              const SizedBox(width: AutolabCustomer.spacingSmd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workshop.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AutolabCustomer.bodyLarge.copyWith(
                        color: AutolabCustomer.customerTextColor(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AutolabCustomer.spacingXs),
                    Text(
                      workshop.locationAddress.isNotEmpty
                          ? workshop.locationAddress
                          : l10n.mapSheetFallbackAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AutolabCustomer.caption.copyWith(
                        color: AutolabCustomer.customerSecondaryTextColor(
                          context,
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AutolabCustomer.spacingSm),
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
                tooltip: l10n.mapSheetViewOnMapTooltip,
                onPressed: onSelected,
                icon: const Icon(
                  Icons.location_searching_rounded,
                  color: AutolabCustomer.primary,
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
  const _WorkshopCoverThumb({required this.workshop, this.size = 82});

  final Workshop workshop;
  final double size;

  @override
  Widget build(BuildContext context) {
    final imageUrl = workshop.coverUrl.isNotEmpty
        ? workshop.coverUrl
        : workshop.avatarUrl;

    final fallback = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AutolabCustomer.secondary,
            AutolabCustomer.darkSurface,
            AutolabCustomer.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        Icons.build_rounded,
        color: AutolabCustomer.white,
        size: AutolabCustomer.responsiveDouble(
          context,
          compact: 24,
          regular: 28,
          tablet: 32,
        ),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(AutolabCustomer.radiusMd),
      child: imageUrl.isEmpty
          ? fallback
          : Image.network(
              imageUrl,
              width: size,
              height: size,
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
      padding: const EdgeInsets.symmetric(
        horizontal: AutolabCustomer.spacingSmd,
        vertical: AutolabCustomer.spacingSm,
      ),
      decoration: BoxDecoration(
        color: AutolabCustomer.customerSoftSurfaceColor(context),
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AutolabCustomer.caption.copyWith(
              color: AutolabCustomer.customerSecondaryTextColor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AutolabCustomer.spacingXs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AutolabCustomer.body.copyWith(
              color: AutolabCustomer.customerTextColor(context),
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
        color: AutolabCustomer.customerElevatedSurfaceColor(
          context,
        ).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AutolabCustomer.secondary.withValues(alpha: 0.07),
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
            icon: Icon(
              Icons.add,
              color: AutolabCustomer.customerTextColor(context),
              size: AutolabCustomer.iconMd,
            ),
          ),
          Container(
            width: 36,
            height: 1,
            color: AutolabCustomer.customerBorderColor(context),
          ),
          IconButton(
            key: const ValueKey('map-zoom-out-button'),
            tooltip: l10n.mapZoomOutTooltip,
            onPressed: onZoomOut,
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.remove,
              color: AutolabCustomer.customerTextColor(context),
              size: AutolabCustomer.iconMd,
            ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AutolabCustomer.spacingSm,
        vertical: AutolabCustomer.spacingXs,
      ),
      decoration: BoxDecoration(
        color: AutolabCustomer.customerChipBackgroundColor(context),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AutolabCustomer.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: AutolabCustomer.caption.copyWith(
              color: AutolabCustomer.customerSecondaryTextColor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapFloatingButton extends StatelessWidget {
  const _MapFloatingButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AutolabCustomer.customerElevatedSurfaceColor(
            context,
          ).withValues(alpha: 0.96),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AutolabCustomer.secondary.withValues(alpha: 0.09),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: SizedBox(
          width: 50,
          height: 50,
          child: IconButton(
            tooltip: tooltip,
            onPressed: onPressed,
            padding: EdgeInsets.zero,
            icon: Icon(
              icon,
              size: AutolabCustomer.iconMd,
              color: AutolabCustomer.customerTextColor(context),
            ),
          ),
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
        color: AutolabCustomer.customerElevatedSurfaceColor(
          context,
        ).withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AutolabCustomer.secondary.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AutolabCustomer.spacingMd),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AutolabCustomer.customerSoftSurfaceColor(context),
                borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
              ),
              child: Icon(
                icon,
                color: AutolabCustomer.customerTextColor(context),
                size: AutolabCustomer.iconSm,
              ),
            ),
            const SizedBox(width: AutolabCustomer.spacingSmd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AutolabCustomer.body.copyWith(
                      color: AutolabCustomer.customerTextColor(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AutolabCustomer.spacingXs),
                  Text(
                    message,
                    style: AutolabCustomer.caption.copyWith(
                      color: AutolabCustomer.customerSecondaryTextColor(
                        context,
                      ),
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
        color: AutolabCustomer.customerElevatedSurfaceColor(
          context,
        ).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AutolabCustomer.secondary.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AutolabCustomer.spacingMd),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AutolabCustomer.caption.copyWith(
            color: AutolabCustomer.customerSecondaryTextColor(context),
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}
