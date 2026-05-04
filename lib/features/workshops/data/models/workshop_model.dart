import '../../domain/entities/workshop.dart';

class WorkshopModel extends Workshop {
  const WorkshopModel({
    required super.id,
    required super.name,
    required super.description,
    required super.locationAddress,
    super.phone,
    required super.avatarUrl,
    required super.coverUrl,
    required super.latitude,
    required super.longitude,
    required super.deliveryRadiusKm,
    super.offersHomeService,
    super.businessHours,
    super.serviceCategories,
    super.paymentMethods,
  });

  factory WorkshopModel.fromMap(Map<String, dynamic> map) {
    return WorkshopModel(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      locationAddress: map['location_address'] ?? '',
      phone: map['phone'] ?? '',
      avatarUrl: map['avatar_url'] ?? '',
      coverUrl: map['cover_url'] ?? '',
      latitude: _toDouble(map['location_lat']),
      longitude: _toDouble(map['location_lng']),
      deliveryRadiusKm: _toDouble(map['delivery_radius_km']),
      offersHomeService: map['offers_home_service'] == true,
      businessHours: _businessHoursFromMap(map),
      serviceCategories: _serviceCategoriesFromMap(map),
      paymentMethods: _paymentMethodsFromMap(map),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }

  static List<WorkshopBusinessHour> _businessHoursFromMap(
    Map<String, dynamic> map,
  ) {
    final items = map['business_hours'];

    if (items is! List) {
      return const [];
    }

    final hours = items
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => WorkshopBusinessHour(
            dayOfWeek: item['day_of_week'] is int ? item['day_of_week'] : 0,
            openTime: item['open_time']?.toString() ?? '',
            closeTime: item['close_time']?.toString() ?? '',
            isClosed: item['is_closed'] == true,
          ),
        )
        .toList();

    hours.sort((left, right) => left.dayOfWeek.compareTo(right.dayOfWeek));

    return hours;
  }

  static List<String> _serviceCategoriesFromMap(Map<String, dynamic> map) {
    final items = map['workshop_service_categories'];

    if (items is! List) {
      return const [];
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map((item) => item['workshop_categories'])
        .whereType<Map<String, dynamic>>()
        .map((category) => category['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
  }

  static List<String> _paymentMethodsFromMap(Map<String, dynamic> map) {
    final items = map['workshop_payment_methods'];

    if (items is! List) {
      return const [];
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map((item) => item['payment_methods'])
        .whereType<Map<String, dynamic>>()
        .map((method) => method['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
  }
}
