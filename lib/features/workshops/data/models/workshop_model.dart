import '../../domain/entities/workshop.dart';

class WorkshopModel extends Workshop {
  const WorkshopModel({
    required super.id,
    required super.name,
    required super.description,
    required super.avatarUrl,
    required super.coverUrl,
    required super.latitude,
    required super.longitude,
  });

  factory WorkshopModel.fromMap(Map<String, dynamic> map) {
    return WorkshopModel(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      avatarUrl: map['avatar_url'] ?? '',
      coverUrl: map['cover_url'] ?? '',
      latitude: (map['location_lat'] ?? 0).toDouble(),
      longitude: (map['location_lng'] ?? 0).toDouble(),
    );
  }
}