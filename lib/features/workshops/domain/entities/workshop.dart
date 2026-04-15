class Workshop {
  final String id;
  final String name;
  final String description;
  final String avatarUrl;
  final String coverUrl;
  final double latitude;
  final double longitude;
  final double deliveryRadiusKm;

  const Workshop({
    required this.id,
    required this.name,
    required this.description,
    required this.avatarUrl,
    required this.coverUrl,
    required this.latitude,
    required this.longitude,
    required this.deliveryRadiusKm,
  });

  bool get hasValidCoordinates {
    return latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        !(latitude == 0 && longitude == 0);
  }

  bool get hasValidDeliveryRadius {
    return deliveryRadiusKm.isFinite && deliveryRadiusKm > 0;
  }
}
