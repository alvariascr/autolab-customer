import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/garage_vehicle_model.dart';

class GarageVehicleAlreadyExistsException implements Exception {
  const GarageVehicleAlreadyExistsException();
}

class GarageVehicleRemoteDataSource {
  const GarageVehicleRemoteDataSource(this.client);

  final SupabaseClient client;
  static const _vehicleImagesBucket = 'garage-vehicle-images';

  static const _select = '''
    id,
    license_plate,
    vehicle_type,
    brand,
    model,
    year,
    color,
    fuel_type,
    transmission_type,
    is_default,
    image_path
  ''';

  Future<List<GarageVehicleModel>> getVehicles() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      return const [];
    }

    final response = await client
        .from('garage_vehicles')
        .select(_select)
        .eq('user_id', userId)
        .eq('is_active', true)
        .order('updated_at', ascending: false);

    return Future.wait(response.map(_vehicleFromMap));
  }

  Future<String> createVehicle({
    required String licensePlate,
    String? vehicleType,
    String? brand,
    String? model,
    int? year,
    String? color,
    String? fuelType,
    String? transmissionType,
  }) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Authenticated user is required');
    }

    final normalizedPlate = _normalizeLicensePlate(licensePlate);
    final existingVehicle = await client
        .from('garage_vehicles')
        .select('id')
        .eq('user_id', userId)
        .eq('license_plate', normalizedPlate)
        .eq('is_active', true)
        .maybeSingle();

    if (existingVehicle != null) {
      throw const GarageVehicleAlreadyExistsException();
    }

    try {
      final response = await client
          .from('garage_vehicles')
          .insert({
            'user_id': userId,
            'license_plate': normalizedPlate,
            'vehicle_type': _trimOrNull(vehicleType),
            'brand': _trimOrNull(brand),
            'model': _trimOrNull(model),
            'year': year,
            'color': _trimOrNull(color),
            'fuel_type': fuelType,
            'transmission_type': transmissionType,
            'is_active': true,
          })
          .select('id')
          .single();

      return response['id'].toString();
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw const GarageVehicleAlreadyExistsException();
      }

      rethrow;
    }
  }

  Future<void> updateVehicle({
    required String id,
    required String licensePlate,
    String? vehicleType,
    String? brand,
    String? model,
    int? year,
    String? color,
    String? fuelType,
    String? transmissionType,
  }) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Authenticated user is required');
    }

    final normalizedPlate = _normalizeLicensePlate(licensePlate);
    final existingVehicle = await client
        .from('garage_vehicles')
        .select('id')
        .eq('user_id', userId)
        .eq('license_plate', normalizedPlate)
        .eq('is_active', true)
        .neq('id', id)
        .maybeSingle();

    if (existingVehicle != null) {
      throw const GarageVehicleAlreadyExistsException();
    }

    try {
      await client
          .from('garage_vehicles')
          .update({
            'license_plate': normalizedPlate,
            'vehicle_type': _trimOrNull(vehicleType),
            'brand': _trimOrNull(brand),
            'model': _trimOrNull(model),
            'year': year,
            'color': _trimOrNull(color),
            'fuel_type': fuelType,
            'transmission_type': transmissionType,
          })
          .eq('id', id)
          .eq('user_id', userId)
          .eq('is_active', true);
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw const GarageVehicleAlreadyExistsException();
      }

      rethrow;
    }
  }

  Future<void> deleteVehicle(String id) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Authenticated user is required');
    }

    await client
        .from('garage_vehicles')
        .update({'is_active': false, 'is_default': false})
        .eq('id', id)
        .eq('user_id', userId);
  }

  Future<void> setDefaultGarageVehicle(String garageVehicleId) async {
    await client.rpc<void>(
      'set_default_garage_vehicle',
      params: {'p_garage_vehicle_id': garageVehicleId},
    );
  }

  Future<void> uploadVehicleImage({
    required String garageVehicleId,
    required String localFilePath,
  }) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Authenticated user is required');
    }

    final file = File(localFilePath);
    final bytes = await file.readAsBytes();
    final objectPath = '$userId/$garageVehicleId/vehicle-image';

    await client.storage
        .from(_vehicleImagesBucket)
        .uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: _imageContentType(path.extension(localFilePath)),
            cacheControl: '3600',
          ),
        );

    await client
        .from('garage_vehicles')
        .update({
          'image_path': objectPath,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', garageVehicleId)
        .eq('user_id', userId)
        .eq('is_active', true);
  }

  Future<GarageVehicleModel> _vehicleFromMap(Map<String, dynamic> map) async {
    final imagePath = map['image_path']?.toString().trim();
    String? imageUrl;
    if (imagePath != null && imagePath.isNotEmpty) {
      try {
        imageUrl = await client.storage
            .from(_vehicleImagesBucket)
            .createSignedUrl(imagePath, 3600);
      } on StorageException {
        // A missing image must not prevent the garage from loading.
      }
    }
    return GarageVehicleModel.fromMap(map, imageUrl: imageUrl);
  }
}

String _imageContentType(String extension) {
  return switch (extension.toLowerCase()) {
    '.png' => 'image/png',
    '.webp' => 'image/webp',
    '.heic' => 'image/heic',
    _ => 'image/jpeg',
  };
}

String? _trimOrNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }

  return trimmed;
}

String _normalizeLicensePlate(String value) {
  final normalized = value.trim().toUpperCase();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, 'licensePlate', 'is required');
  }

  return normalized;
}
