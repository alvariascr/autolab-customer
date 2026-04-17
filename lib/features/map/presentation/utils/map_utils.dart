import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../workshops/domain/entities/workshop.dart';

List<Marker> buildMarkers(List<Workshop> workshops) {
  return workshops
      .where(
        (w) =>
    w.latitude >= -90 &&
        w.latitude <= 90 &&
        w.longitude >= -180 &&
        w.longitude <= 180,
  )
      .map(
        (w) => Marker(
      point: LatLng(w.latitude, w.longitude),
      width: 40,
      height: 40,
      child: const Icon(
        Icons.location_on,
        color: Colors.red,
        size: 30,
      ),
    ),
  )
      .toList();
}