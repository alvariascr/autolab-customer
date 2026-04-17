import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../navigation/navigation_handler.dart';
import '../../../navigation/widgets/custom_bottom_navbar.dart';
import '../../../workshops/domain/entities/workshop.dart';
import '../utils/map_utils.dart';

class MapPage extends StatefulWidget {
  final List<Workshop> workshops;

  const MapPage({
    super.key,
    required this.workshops,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  int _currentIndex = 1;
  bool _showSearchBar = false;

  void _handleBottomNavigation(int index) {
    if (index == 2) {
      setState(() {
        _currentIndex = 2;
        _showSearchBar = !_showSearchBar;
      });
      return;
    }

    setState(() {
      _currentIndex = index;
      _showSearchBar = false;
    });

    NavigationHandler.handle(
      context,
      index,
      workshops: widget.workshops,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final markers = buildMarkers(widget.workshops);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Mapa'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: widget.workshops.isNotEmpty
                          ? LatLng(
                        widget.workshops.first.latitude,
                        widget.workshops.first.longitude,
                      )
                          : const LatLng(9.9281, -84.0907),
                      initialZoom: 12,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.autolab.customer',
                      ),
                      MarkerLayer(
                        markers: markers,
                      ),
                    ],
                  ),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Column(
                      children: [
                        FloatingActionButton(
                          heroTag: 'map_zoom_in',
                          mini: true,
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          onPressed: () {
                            _mapController.move(
                              _mapController.camera.center,
                              _mapController.camera.zoom + 1,
                            );
                          },
                          child: const Icon(Icons.add),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton(
                          heroTag: 'map_zoom_out',
                          mini: true,
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          onPressed: () {
                            _mapController.move(
                              _mapController.camera.center,
                              _mapController.camera.zoom - 1,
                            );
                          },
                          child: const Icon(Icons.remove),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            top: _showSearchBar ? 16 : -100,
            left: 16,
            right: 16,
            child: Material(
              elevation: 10,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: _showSearchBar,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.search),
                    hintText: 'Buscar talleres...',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: _currentIndex,
        onTap: _handleBottomNavigation,
      ),
    );
  }
}