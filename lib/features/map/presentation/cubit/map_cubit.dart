import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/location/current_location.dart';
import '../../../../core/logging/feature_logger.dart';
import '../../../workshops/domain/entities/workshop.dart';
import '../../../workshops/domain/repositories/workshop_repository.dart';
import '../../../workshops/domain/services/workshop_proximity_filter.dart';
import '../../../workshops/domain/services/workshop_search_location_resolver.dart';
import 'map_state.dart';

class MapCubit extends Cubit<MapState> {
  MapCubit(this._repository, this._featureLogger) : super(const MapInitial());

  final WorkshopRepository _repository;
  final FeatureLogger _featureLogger;
  static const _proximityFilter = WorkshopProximityFilter();
  static const _searchLocationResolver = WorkshopSearchLocationResolver();

  List<Workshop>? _allWorkshops;

  Future<void> loadWorkshops(CurrentLocation? userLocation) async {
    _featureLogger.info(
      feature: 'map',
      action: 'load_workshops_started',
      context: {'hasUserLocation': userLocation != null},
    );

    if (_allWorkshops == null) {
      emit(const MapLoading());
    }

    final result = await _repository.getWorkshops();

    result.fold(
      (failure) {
        _featureLogger.warn(
          feature: 'map',
          action: 'load_workshops_failed',
          code: failure.code,
          context: {'uiKey': failure.uiKey},
          error: failure.cause,
          stackTrace: failure.stackTrace,
        );

        emit(
          MapError(
            code: failure.code ?? 'UNK_001',
            uiKey: failure.uiKey,
            message: failure.message,
          ),
        );
      },
      (workshops) {
        _allWorkshops = workshops;
        final searchLocation = _searchLocationResolver.resolve(userLocation);
        final nearbyWorkshops = _proximityFilter.filterNearby(
          workshops: workshops,
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

        _featureLogger.info(
          feature: 'map',
          action: 'load_workshops_succeeded',
          context: {
            'totalWorkshops': workshops.length,
            'nearbyWorkshops': nearbyWorkshops.length,
            'usingFallbackLocation': _searchLocationResolver.isUsingFallback(
              userLocation,
            ),
          },
        );
      },
    );
  }
}
