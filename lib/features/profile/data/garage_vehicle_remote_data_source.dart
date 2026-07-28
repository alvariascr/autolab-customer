import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/repositories/garage_vehicle_repository.dart';
import 'models/garage_vehicle_model.dart';

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

    return _vehiclesFromMaps(response);
  }

  Future<GarageVehicleModel?> getDefaultVehicle() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await client
        .from('garage_vehicles')
        .select(_select)
        .eq('user_id', userId)
        .eq('is_active', true)
        .eq('is_default', true)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return (await _vehiclesFromMaps([response])).single;
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

    final existingVehicle = await client
        .from('garage_vehicles')
        .select('image_path')
        .eq('id', garageVehicleId)
        .eq('user_id', userId)
        .eq('is_active', true)
        .maybeSingle();
    if (existingVehicle == null) {
      throw StateError('Active garage vehicle was not found');
    }

    final contentType = _imageContentType(path.extension(localFilePath));
    final bytes = await XFile(localFilePath).readAsBytes();
    final previousObjectPath = existingVehicle['image_path']?.toString().trim();
    final imageVersion = DateTime.now().toUtc().microsecondsSinceEpoch;
    final objectPath = '$userId/$garageVehicleId/vehicle-image-$imageVersion';

    await client.storage
        .from(_vehicleImagesBucket)
        .uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(
            upsert: false,
            contentType: contentType,
            cacheControl: '3600',
          ),
        );

    final updatedVehicle = await client
        .from('garage_vehicles')
        .update({
          'image_path': objectPath,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', garageVehicleId)
        .eq('user_id', userId)
        .eq('is_active', true)
        .select('id')
        .maybeSingle();

    if (updatedVehicle == null) {
      try {
        await client.storage.from(_vehicleImagesBucket).remove([objectPath]);
      } on StorageException {
        // Preserve the persistence error even if orphan cleanup also fails.
      }
      throw StateError('Active garage vehicle was not found');
    }

    if (previousObjectPath != null &&
        previousObjectPath.isNotEmpty &&
        previousObjectPath != objectPath) {
      try {
        await client.storage.from(_vehicleImagesBucket).remove([
          previousObjectPath,
        ]);
      } on StorageException {
        // The new image is already persisted; stale-object cleanup can retry.
      }
    }
  }

  Future<List<GarageVehicleModel>> _vehiclesFromMaps(
    List<Map<String, dynamic>> maps,
  ) async {
    final imagePaths = maps
        .map((map) => map['image_path']?.toString().trim())
        .whereType<String>()
        .where((imagePath) => imagePath.isNotEmpty)
        .toSet()
        .toList();
    final signedUrlsByPath = <String, String>{};

    if (imagePaths.isNotEmpty) {
      try {
        final signedUrls = await client.storage
            .from(_vehicleImagesBucket)
            .createSignedUrls(imagePaths, 3600);
        for (final signedUrl in signedUrls) {
          if (signedUrl.path.isNotEmpty && signedUrl.signedUrl.isNotEmpty) {
            signedUrlsByPath[signedUrl.path] = signedUrl.signedUrl;
          }
        }
      } on StorageException {
        // Missing images must not prevent the garage from loading.
      }
    }

    return maps.map((map) {
      final imagePath = map['image_path']?.toString().trim();
      return GarageVehicleModel.fromMap(
        map,
        imageUrl: imagePath == null ? null : signedUrlsByPath[imagePath],
      );
    }).toList();
  }
}

String _imageContentType(String extension) {
  return switch (extension.toLowerCase()) {
    '.jpg' || '.jpeg' => 'image/jpeg',
    '.png' => 'image/png',
    '.webp' => 'image/webp',
    '.heic' => 'image/heic',
    _ => throw UnsupportedError(
      'Unsupported garage vehicle image extension: $extension',
    ),
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
