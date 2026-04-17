import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../workshops/domain/repositories/workshop_repository.dart';
import 'map_state.dart';

class MapCubit extends Cubit<MapState> {
  final WorkshopRepository repository;

  MapCubit(this.repository) : super(MapInitial());

  Future<void> loadWorkshops() async {
    emit(MapLoading());

    try {
      final workshops = await repository.getWorkshops();
      emit(MapLoaded(workshops));
    } catch (e) {
      emit(MapError(e.toString()));
    }
  }
}