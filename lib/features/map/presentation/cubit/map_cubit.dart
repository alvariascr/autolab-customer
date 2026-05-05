import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/location/current_location.dart';
import '../../../../core/logging/feature_logger.dart';
import '../../../workshops/application/workshop_discovery_query_store.dart';
import '../../../workshops/domain/entities/workshop.dart';
import '../../../workshops/domain/repositories/workshop_repository.dart';
import '../../../workshops/domain/services/workshop_discovery_filter.dart';
import '../../../workshops/domain/services/workshop_search_location_resolver.dart';
import 'map_state.dart';

class MapCubit extends Cubit<MapState> {
  MapCubit(
    this._repository,
    this._featureLogger, {
    WorkshopDiscoveryQueryStore? queryStore,
  }) : _queryStore = queryStore,
       super(const MapInitial());

  final WorkshopRepository _repository;
  final FeatureLogger _featureLogger;
  final WorkshopDiscoveryQueryStore? _queryStore;
  static const _searchLocationResolver = WorkshopSearchLocationResolver();
  static const _discoveryFilter = WorkshopDiscoveryFilter();

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
        final nearbyWorkshops = _discoveryFilter.apply(
          workshops: workshops,
          currentLocation: searchLocation,
          query: _queryStore?.query ?? '',
        );

        emit(
          MapLoaded(
            nearbyWorkshops,
            currentLocation: searchLocation,
            isUsingFallbackLocation: _searchLocationResolver.isUsingFallback(
              userLocation,
            ),
            query: _queryStore?.query ?? '',
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
