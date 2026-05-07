import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../workshops/domain/entities/workshop.dart';

Set<Marker> buildMarkers(List<Workshop> workshops) {
  return workshops
      .where((workshop) => workshop.hasValidCoordinates)
      .map(
        (w) => Marker(
          markerId: MarkerId('workshop-${w.id}'),
          position: LatLng(w.latitude, w.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: w.name),
        ),
      )
      .toSet();
}
