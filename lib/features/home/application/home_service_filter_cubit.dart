import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/usecases/get_home_service_workshop_ids.dart';
import 'home_service_filter_state.dart';

class HomeServiceFilterCubit extends Cubit<HomeServiceFilterState> {
  HomeServiceFilterCubit({
    required GetHomeServiceWorkshopIds getHomeServiceWorkshopIds,
  }) : _getHomeServiceWorkshopIds = getHomeServiceWorkshopIds,
       super(HomeServiceFilterState());

  final GetHomeServiceWorkshopIds _getHomeServiceWorkshopIds;
  int _requestGeneration = 0;

  Future<void> select({
    required String serviceKey,
    required String serviceLabel,
  }) async {
    final generation = ++_requestGeneration;
    emit(
      HomeServiceFilterState(
        status: HomeServiceFilterStatus.loading,
        serviceKey: serviceKey,
        serviceLabel: serviceLabel,
      ),
    );

    try {
      final result = await _getHomeServiceWorkshopIds(serviceKey);
      if (isClosed || generation != _requestGeneration) return;

      result.fold(
        (_) => emit(
          HomeServiceFilterState(
            status: HomeServiceFilterStatus.failure,
            serviceKey: serviceKey,
            serviceLabel: serviceLabel,
          ),
        ),
        (workshopIds) {
          emit(
            HomeServiceFilterState(
              status: HomeServiceFilterStatus.success,
              serviceKey: serviceKey,
              serviceLabel: serviceLabel,
              matchingWorkshopIds: workshopIds,
            ),
          );
        },
      );
    } catch (_) {
      if (isClosed || generation != _requestGeneration) return;
      emit(
        HomeServiceFilterState(
          status: HomeServiceFilterStatus.failure,
          serviceKey: serviceKey,
          serviceLabel: serviceLabel,
        ),
      );
    }
  }

  void clear() {
    _requestGeneration++;
    emit(HomeServiceFilterState());
  }
}
