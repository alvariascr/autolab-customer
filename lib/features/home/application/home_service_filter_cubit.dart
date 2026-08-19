import 'package:flutter_bloc/flutter_bloc.dart';

import '../../products/domain/repositories/product_repository.dart';
import '../domain/home_service_inventory_matcher.dart';
import 'home_service_filter_state.dart';

class HomeServiceFilterCubit extends Cubit<HomeServiceFilterState> {
  HomeServiceFilterCubit({
    required ProductRepository productRepository,
    HomeServiceInventoryMatcher matcher = const HomeServiceInventoryMatcher(),
  }) : _productRepository = productRepository,
       _matcher = matcher,
       super(HomeServiceFilterState());

  final ProductRepository _productRepository;
  final HomeServiceInventoryMatcher _matcher;
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
      final result = await _productRepository.getActiveProducts();
      if (isClosed || generation != _requestGeneration) return;

      result.fold(
        (_) => emit(
          HomeServiceFilterState(
            status: HomeServiceFilterStatus.failure,
            serviceKey: serviceKey,
            serviceLabel: serviceLabel,
          ),
        ),
        (products) {
          final workshopIds = products
              .where((product) => _matcher.matchesProduct(serviceKey, product))
              .map((product) => product.workshopId)
              .where((workshopId) => workshopId.trim().isNotEmpty)
              .toSet()
              .toList(growable: false);
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
