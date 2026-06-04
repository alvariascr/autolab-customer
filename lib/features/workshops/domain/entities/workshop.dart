class Workshop {
  final String id;
  final String name;
  final String description;
  final String locationAddress;
  final String phone;
  final String avatarUrl;
  final String coverUrl;
  final double latitude;
  final double longitude;
  final double deliveryRadiusKm;
  final bool offersHomeService;
  final List<WorkshopBusinessHour> businessHours;
  final List<String> serviceCategories;
  final List<String> paymentMethods;

  const Workshop({
    required this.id,
    required this.name,
    required this.description,
    required this.locationAddress,
    this.phone = '',
    required this.avatarUrl,
    required this.coverUrl,
    required this.latitude,
    required this.longitude,
    required this.deliveryRadiusKm,
    this.offersHomeService = false,
    this.businessHours = const [],
    this.serviceCategories = const [],
    this.paymentMethods = const [],
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

class WorkshopBusinessHour {
  final int dayOfWeek;
  final String openTime;
  final String closeTime;
  final bool isClosed;
  final int slotCapacity;

  const WorkshopBusinessHour({
    required this.dayOfWeek,
    required this.openTime,
    required this.closeTime,
    required this.isClosed,
    this.slotCapacity = 1,
  }) : assert(slotCapacity > 0, 'slotCapacity must be greater than 0');
}
