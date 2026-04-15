import 'package:geocoding/geocoding.dart' as geocoding;

abstract class GeocodingClient {
  Future<List<geocoding.Placemark>> placemarkFromCoordinates(
    double latitude,
    double longitude,
  );
}

class DefaultGeocodingClient implements GeocodingClient {
  const DefaultGeocodingClient();

  @override
  Future<List<geocoding.Placemark>> placemarkFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    return geocoding.placemarkFromCoordinates(latitude, longitude);
  }
}
