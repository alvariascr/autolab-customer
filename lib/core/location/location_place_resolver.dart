import 'package:geocoding/geocoding.dart';

import 'current_location.dart';
import 'geocoding_client.dart';

abstract class LocationPlaceResolver {
  Future<LocationPlaceResolution> resolvePlaceName(CurrentLocation location);
}

class GeocodingLocationPlaceResolver implements LocationPlaceResolver {
  GeocodingLocationPlaceResolver(this._geocodingClient);

  final GeocodingClient _geocodingClient;

  @override
  Future<LocationPlaceResolution> resolvePlaceName(
    CurrentLocation location,
  ) async {
    final placemarks = await _geocodingClient.placemarkFromCoordinates(
      location.latitude,
      location.longitude,
    );

    if (placemarks.isEmpty) {
      return const LocationPlaceResolution(
        placeName: null,
        debugDetails: 'placemarks: empty',
      );
    }

    final placemark = placemarks.first;

    return LocationPlaceResolution(
      placeName: _buildDisplayName(placemark),
      debugDetails:
          'name=${placemark.name}; subLocality=${placemark.subLocality}; locality=${placemark.locality}; subAdministrativeArea=${placemark.subAdministrativeArea}; administrativeArea=${placemark.administrativeArea}; country=${placemark.country}; street=${placemark.street}; thoroughfare=${placemark.thoroughfare}',
    );
  }

  String? _buildDisplayName(Placemark placemark) {
    final areaParts = [
      placemark.subLocality,
      placemark.locality,
      placemark.subAdministrativeArea,
      placemark.administrativeArea,
    ].where(_hasMeaningfulValue).cast<String>().toList();

    final normalizedAreaParts = _uniqueParts(areaParts);
    if (normalizedAreaParts.isNotEmpty) {
      return normalizedAreaParts.join(', ');
    }

    final primaryParts = [
      placemark.subLocality,
      placemark.locality,
      placemark.subAdministrativeArea,
      placemark.administrativeArea,
      placemark.country,
      if (_hasMeaningfulValue(placemark.name)) placemark.name,
    ].where(_hasValue).cast<String>().toList();

    final normalizedPrimaryParts = _uniqueParts(primaryParts);
    if (normalizedPrimaryParts.isNotEmpty) {
      return normalizedPrimaryParts.join(', ');
    }

    final fallbackParts = [
      placemark.thoroughfare,
      placemark.subThoroughfare,
      placemark.street,
      if (_hasMeaningfulValue(placemark.name)) placemark.name,
      placemark.country,
    ].where(_hasValue).cast<String>().toList();

    final normalizedFallbackParts = _uniqueParts(fallbackParts);
    if (normalizedFallbackParts.isEmpty) {
      return null;
    }

    return normalizedFallbackParts.join(', ');
  }

  bool _hasValue(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  bool _hasMeaningfulValue(String? value) {
    if (!_hasValue(value)) {
      return false;
    }

    final normalized = value!.trim();
    final plusCodePattern = RegExp(
      r'^[23456789CFGHJMPQRVWX]{4,}\+[23456789CFGHJMPQRVWX]{2,}$',
      caseSensitive: false,
    );

    return !plusCodePattern.hasMatch(normalized);
  }

  List<String> _uniqueParts(List<String> parts) {
    final seen = <String>{};
    final unique = <String>[];

    for (final part in parts) {
      final normalized = part.trim().toLowerCase();
      if (seen.add(normalized)) {
        unique.add(part.trim());
      }
    }

    return unique;
  }
}

class LocationPlaceResolution {
  const LocationPlaceResolution({
    required this.placeName,
    required this.debugDetails,
  });

  final String? placeName;
  final String debugDetails;
}
