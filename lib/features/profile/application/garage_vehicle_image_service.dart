import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/garage_vehicle.dart';
import '../domain/repositories/garage_vehicle_repository.dart';

class GarageVehicleMovedImage {
  const GarageVehicleMovedImage({
    required this.preferenceKey,
    required this.localPath,
  });

  final String preferenceKey;
  final String localPath;
}

class GarageVehicleImageService {
  const GarageVehicleImageService(this._repository, this._preferences);

  static const imageKeyPrefix = 'garage_vehicle_image_';
  static const newVehicleImageKey = '${imageKeyPrefix}new';

  final GarageVehicleRepository _repository;
  final SharedPreferences _preferences;

  Future<Map<String, String>> loadLocalImages() async {
    final loadedPaths = <String, String>{};

    for (final key in _preferences.getKeys()) {
      if (!key.startsWith(imageKeyPrefix)) continue;

      final path = _preferences.getString(key);
      if (path == null || path.isEmpty || !File(path).existsSync()) continue;
      loadedPaths[key] = path;
    }

    return loadedPaths;
  }

  Future<String> persistImage({
    required String sourcePath,
    required String preferenceKey,
  }) async {
    final persistedPath = await _copyToApplicationStorage(
      sourcePath: sourcePath,
      preferenceKey: preferenceKey,
    );
    await _preferences.setString(preferenceKey, persistedPath);
    return persistedPath;
  }

  Future<void> uploadPersistedImage({
    required String vehicleId,
    required String localPath,
    required String preferenceKey,
  }) async {
    await _repository.uploadVehicleImage(
      garageVehicleId: vehicleId,
      localFilePath: localPath,
    );
    await _preferences.remove(preferenceKey);
  }

  Future<void> removeNewVehicleImage() =>
      _preferences.remove(newVehicleImageKey);

  Future<GarageVehicleMovedImage?> moveAndUploadNewVehicleImage(
    String vehicleId,
  ) async {
    final temporaryPath = _preferences.getString(newVehicleImageKey);
    if (temporaryPath == null || temporaryPath.isEmpty) return null;

    final preferenceKey = vehicleImageKey(vehicleId);
    final persistedPath = await persistImage(
      sourcePath: temporaryPath,
      preferenceKey: preferenceKey,
    );
    await _preferences.remove(newVehicleImageKey);
    await uploadPersistedImage(
      vehicleId: vehicleId,
      localPath: persistedPath,
      preferenceKey: preferenceKey,
    );

    return GarageVehicleMovedImage(
      preferenceKey: preferenceKey,
      localPath: persistedPath,
    );
  }

  Future<bool> uploadLegacyImages(List<GarageVehicle> vehicles) async {
    var uploadedAny = false;

    for (final vehicle in vehicles.where(
      (vehicle) => vehicle.imagePath == null || vehicle.imagePath!.isEmpty,
    )) {
      final preferenceKey = vehicleImageKey(vehicle.id);
      final localPath = _preferences.getString(preferenceKey);
      if (localPath == null ||
          localPath.isEmpty ||
          !File(localPath).existsSync()) {
        continue;
      }

      try {
        await uploadPersistedImage(
          vehicleId: vehicle.id,
          localPath: localPath,
          preferenceKey: preferenceKey,
        );
        uploadedAny = true;
      } on UnsupportedError {
        await _preferences.remove(preferenceKey);
      } catch (_) {
        // Keep the local path so migration can retry on the next load.
      }
    }

    return uploadedAny;
  }

  static String vehicleImageKey(String vehicleId) =>
      '$imageKeyPrefix$vehicleId';

  Future<String> _copyToApplicationStorage({
    required String sourcePath,
    required String preferenceKey,
  }) async {
    final sourceFile = File(sourcePath);
    final appDirectory = await getApplicationDocumentsDirectory();
    final imagesDirectory = Directory(
      '${appDirectory.path}${Platform.pathSeparator}garage_vehicle_images',
    );

    if (!imagesDirectory.existsSync()) {
      await imagesDirectory.create(recursive: true);
    }

    final extension = _fileExtension(sourceFile.path);
    final fileName =
        '${preferenceKey}_${DateTime.now().microsecondsSinceEpoch}$extension';
    final destinationPath =
        '${imagesDirectory.path}${Platform.pathSeparator}$fileName';

    final copiedFile = await sourceFile.copy(destinationPath);
    return copiedFile.path;
  }
}

String _fileExtension(String path) {
  final dotIndex = path.lastIndexOf('.');
  if (dotIndex == -1 || dotIndex == path.length - 1) return '.jpg';
  return path.substring(dotIndex);
}
