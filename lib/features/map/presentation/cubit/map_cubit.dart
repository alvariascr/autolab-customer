import 'dart:async';
import 'dart:io';

import 'package:autolab_core/autolab_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/customer_error_catalog.dart';
import '../../../../core/location/current_location.dart';
import '../../../workshops/domain/entities/workshop.dart';
import '../../../workshops/domain/repositories/workshop_repository.dart';
import '../../../workshops/domain/services/workshop_proximity_filter.dart';
import '../../../workshops/domain/services/workshop_search_location_resolver.dart';
import 'map_state.dart';

class MapCubit extends Cubit<MapState> {
  MapCubit(this._repository, {GlobalErrorHandler? errorHandler})
    : _errorHandler = errorHandler,
      super(const MapInitial());

  final WorkshopRepository _repository;
  final GlobalErrorHandler? _errorHandler;
  static const _proximityFilter = WorkshopProximityFilter();
  static const _searchLocationResolver = WorkshopSearchLocationResolver();

  List<Workshop>? _allWorkshops;

  Future<void> loadWorkshops(CurrentLocation? userLocation) async {
    if (_allWorkshops == null) {
      emit(const MapLoading());
    }

    try {
      _allWorkshops ??= await _repository.getWorkshops();
      final searchLocation = _searchLocationResolver.resolve(userLocation);
      final nearbyWorkshops = _proximityFilter.filterNearby(
        workshops: _allWorkshops!.cast(),
        currentLocation: searchLocation,
      );

      emit(
        MapLoaded(
          nearbyWorkshops,
          currentLocation: searchLocation,
          isUsingFallbackLocation: _searchLocationResolver.isUsingFallback(
            userLocation,
          ),
        ),
      );
    } on TimeoutException catch (error, stackTrace) {
      _emitFailure(
        CustomerErrorCatalog.workshopNetworkError.message,
        error,
        stackTrace,
      );
    } on SocketException catch (error, stackTrace) {
      _emitFailure(
        CustomerErrorCatalog.workshopNetworkError.message,
        error,
        stackTrace,
      );
    } on PostgrestException catch (error, stackTrace) {
      _emitFailure(
        CustomerErrorCatalog.workshopLoadFailed.message,
        error,
        stackTrace,
      );
    } catch (error, stackTrace) {
      _emitFailure(
        CustomerErrorCatalog.workshopLoadFailed.message,
        error,
        stackTrace,
      );
    }
  }

  void _emitFailure(String message, Object error, StackTrace stackTrace) {
    _errorHandler?.handle(error, stackTrace);
    emit(MapError(message));
  }
}
