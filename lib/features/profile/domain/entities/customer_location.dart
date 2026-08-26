import 'package:equatable/equatable.dart';

class CustomerLocation extends Equatable {
  const CustomerLocation({
    required this.id,
    required this.label,
    required this.address,
    required this.country,
    required this.province,
    required this.canton,
    required this.district,
    required this.exactAddress,
    required this.latitude,
    required this.longitude,
    required this.isDefault,
  });

  final String id;
  final String label;
  final String address;
  final String country;
  final String province;
  final String canton;
  final String district;
  final String exactAddress;
  final double latitude;
  final double longitude;
  final bool isDefault;

  String get displayLabel {
    final trimmed = label.trim();
    return trimmed.isEmpty ? address : trimmed;
  }

  @override
  List<Object?> get props => [
    id,
    label,
    address,
    country,
    province,
    canton,
    district,
    exactAddress,
    latitude,
    longitude,
    isDefault,
  ];
}

class CustomerLocationRequest extends Equatable {
  const CustomerLocationRequest({
    required this.label,
    required this.address,
    required this.country,
    required this.province,
    required this.canton,
    required this.district,
    required this.exactAddress,
    required this.latitude,
    required this.longitude,
  });

  final String label;
  final String address;
  final String country;
  final String province;
  final String canton;
  final String district;
  final String exactAddress;
  final double latitude;
  final double longitude;

  @override
  List<Object?> get props => [
    label,
    address,
    country,
    province,
    canton,
    district,
    exactAddress,
    latitude,
    longitude,
  ];
}
