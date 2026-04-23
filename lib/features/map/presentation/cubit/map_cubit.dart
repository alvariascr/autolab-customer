import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/location/current_location.dart';
import '../../../workshops/domain/entities/workshop.dart';
import '../../../workshops/domain/repositories/workshop_repository.dart';
import '../../../workshops/domain/services/workshop_proximity_filter.dart';
import '../../../workshops/domain/services/workshop_search_location_resolver.dart';
import 'map_state.dart';

class MapCubit extends Cubit<MapState> {
  MapCubit(this._repository) : super(const MapInitial());

  final WorkshopRepository _repository;
  static const _proximityFilter = WorkshopProximityFilter();
  static const _searchLocationResolver = WorkshopSearchLocationResolver();

  List<Workshop>? _allWorkshops;

  Future<void> loadWorkshops(CurrentLocation? userLocation) async {
    if (_allWorkshops == null) {
      emit(const MapLoading());
    }

    final result = await _repository.getWorkshops();

    result.fold(
      (failure) => emit(
        MapError(
          code: failure.code ?? 'UNK_001',
          uiKey: failure.uiKey,
          message: failure.message,
        ),
      ),
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
      },
    );
  }
}
