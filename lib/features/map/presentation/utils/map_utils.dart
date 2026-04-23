import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../workshops/domain/entities/workshop.dart';

List<Marker> buildMarkers(List<Workshop> workshops) {
  return workshops
      .where((workshop) => workshop.hasValidCoordinates)
      .map(
        (w) => Marker(
          point: LatLng(w.latitude, w.longitude),
          width: 44,
          height: 44,
          child: const Icon(Icons.location_on, color: Colors.red, size: 32),
        ),
      )
      .toList();
}
