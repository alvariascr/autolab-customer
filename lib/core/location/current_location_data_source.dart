import 'dart:async';

import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';

import '../errors/customer_error_catalog.dart';
import 'current_location.dart';
import 'geolocator_client.dart';

abstract class CurrentLocationDataSource {
  Future<bool> isLocationServiceEnabled();
  Future<Either<Failure, CurrentLocation>> getCurrentLocation();
}

class CurrentLocationDataSourceImpl implements CurrentLocationDataSource {
  CurrentLocationDataSourceImpl(this._geolocatorClient, this._errorHandler);

  final GeolocatorClient _geolocatorClient;
  final GlobalErrorHandler _errorHandler;

  @override
  Future<bool> isLocationServiceEnabled() {
    return _geolocatorClient.isLocationServiceEnabled();
  }

  @override
  Future<Either<Failure, CurrentLocation>> getCurrentLocation() async {
    try {
      final serviceEnabled = await _geolocatorClient.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return Left(
          ValidationFailure.fromErrorItem(
            CustomerErrorCatalog.locationServiceDisabled,
          ),
        );
      }

      final permission = await _geolocatorClient.checkPermission();
      if (!_hasLocationPermission(permission)) {
        return Left(
          ValidationFailure.fromErrorItem(
            CustomerErrorCatalog.locationPermissionRequired,
          ),
        );
      }

      final position = await _geolocatorClient.getCurrentPosition();
      final currentLocation = CurrentLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!currentLocation.hasValidCoordinates) {
        return Left(
          ValidationFailure.fromErrorItem(
            CustomerErrorCatalog.invalidCurrentLocation,
          ),
        );
      }

      return Right(currentLocation);
    } on TimeoutException catch (error, stackTrace) {
      return Left(
        TimeoutFailure.fromErrorItem(
          CustomerErrorCatalog.locationRequestTimeout,
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    } on LocationServiceDisabledException catch (error, stackTrace) {
      return Left(
        ValidationFailure.fromErrorItem(
          CustomerErrorCatalog.locationServiceDisabled,
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    } on PermissionDeniedException catch (error, stackTrace) {
      return Left(
        ValidationFailure.fromErrorItem(
          CustomerErrorCatalog.locationPermissionRequired,
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    } on PermissionDefinitionsNotFoundException catch (error, stackTrace) {
      return Left(
        UnknownFailure.fromErrorItem(
          CustomerErrorCatalog.locationConfigurationIncomplete,
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    } catch (error, stackTrace) {
      return Left(_errorHandler.handle(error, stackTrace));
    }
  }

  bool _hasLocationPermission(LocationPermission permission) {
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }
}
