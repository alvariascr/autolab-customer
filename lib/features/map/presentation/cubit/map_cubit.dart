import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/location/current_location.dart';
import '../../../../core/logging/feature_logger.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/repositories/product_repository.dart';
import '../../../products/domain/services/product_search_filter.dart';
import '../../../products/domain/services/workshop_product_search_grouper.dart';
import '../../../workshops/application/workshop_discovery_query_store.dart';
import '../../../workshops/domain/entities/workshop.dart';
import '../../../workshops/domain/repositories/workshop_repository.dart';
import '../../../workshops/domain/services/workshop_proximity_filter.dart';
import '../../../workshops/domain/services/workshop_search_location_resolver.dart';
import '../../../workshops/domain/services/workshop_text_search_filter.dart';
import 'map_state.dart';

class MapCubit extends Cubit<MapState> {
  MapCubit(
    this._repository,
    this._productRepository,
    this._featureLogger, {
    WorkshopDiscoveryQueryStore? queryStore,
  }) : _queryStore = queryStore,
       super(const MapInitial()) {
    _queryStore?.addListener(_handleQueryChanged);
  }

  final WorkshopRepository _repository;
  final ProductRepository _productRepository;
  final FeatureLogger _featureLogger;
  final WorkshopDiscoveryQueryStore? _queryStore;
  static const _searchLocationResolver = WorkshopSearchLocationResolver();
  static const _proximityFilter = WorkshopProximityFilter();
  static const _textSearchFilter = WorkshopTextSearchFilter();
  static const _productSearchFilter = ProductSearchFilter();
  static const _productSearchGrouper = WorkshopProductSearchGrouper();

  List<Workshop>? _allWorkshops;
  List<Product> _allProducts = const [];
  CurrentLocation? _lastUserLocation;
  bool _isLoadingProducts = false;
  bool _hasLoadedProducts = false;

  @override
  Future<void> close() {
    _queryStore?.removeListener(_handleQueryChanged);
    return super.close();
  }

  void _handleQueryChanged() {
    if (isClosed) {
      return;
    }

    final workshops = _allWorkshops;

    if (workshops == null) {
      return;
    }

    _emitLoaded(workshops, _lastUserLocation);
  }

  Future<void> loadWorkshops(CurrentLocation? userLocation) async {
    if (isClosed) {
      return;
    }

    _lastUserLocation = userLocation;
    _featureLogger.info(
      feature: 'map',
      action: 'load_workshops_started',
      context: {'hasUserLocation': userLocation != null},
    );

    if (_allWorkshops == null && !isClosed) {
      emit(const MapLoading());
    }

    final result = await _repository.getWorkshops();

    if (isClosed) {
      return;
    }

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

        if (!isClosed) {
          emit(
            MapError(
              code: failure.code ?? 'UNK_001',
              uiKey: failure.uiKey,
              message: failure.message,
            ),
          );
        }
      },
      (workshops) {
        _allWorkshops = workshops;
        final nearbyWorkshops = _emitLoaded(workshops, userLocation);
        _loadProductsIfNeeded();

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

  List<Workshop> _emitLoaded(
    List<Workshop> workshops,
    CurrentLocation? userLocation,
  ) {
    final query = _queryStore?.query ?? '';
    final searchLocation = _searchLocationResolver.resolve(userLocation);
    final nearbyWorkshops = _proximityFilter.filterNearby(
      workshops: workshops,
      currentLocation: searchLocation,
    );
    final trimmedQuery = query.trim();
    final workshopResults = trimmedQuery.isEmpty
        ? nearbyWorkshops
        : _textSearchFilter.filter(workshops: nearbyWorkshops, query: query);
    final productResults = trimmedQuery.isEmpty
        ? const <WorkshopProductSearchResult>[]
        : _productSearchGrouper.group(
            products: _productSearchFilter.filter(
              products: _allProducts,
              query: query,
            ),
            workshops: nearbyWorkshops,
          );
    final visibleWorkshops = trimmedQuery.isEmpty
        ? workshopResults
        : _mergeWorkshopResults(workshopResults, productResults);

    if (!isClosed) {
      emit(
        MapLoaded(
          visibleWorkshops,
          currentLocation: searchLocation,
          isUsingFallbackLocation: _searchLocationResolver.isUsingFallback(
            userLocation,
          ),
          query: query,
          productResults: productResults,
          isLoadingProductResults:
              trimmedQuery.isNotEmpty && _isLoadingProducts,
        ),
      );
    }

    return visibleWorkshops;
  }

  List<Workshop> _mergeWorkshopResults(
    List<Workshop> workshopResults,
    List<WorkshopProductSearchResult> productResults,
  ) {
    final byId = <String, Workshop>{
      for (final result in productResults) result.workshop.id: result.workshop,
      for (final workshop in workshopResults) workshop.id: workshop,
    };

    return byId.values.toList(growable: false);
  }

  Future<void> _loadProductsIfNeeded() async {
    if (isClosed || _hasLoadedProducts || _isLoadingProducts) {
      return;
    }

    _isLoadingProducts = true;
    _emitLoaded(_allWorkshops ?? const [], _lastUserLocation);

    final result = await _productRepository.getActiveProducts();

    if (isClosed) {
      return;
    }

    _allProducts = result.fold((failure) {
      _featureLogger.warn(
        feature: 'map',
        action: 'load_products_failed',
        code: failure.code,
        context: {'uiKey': failure.uiKey},
        error: failure.cause,
        stackTrace: failure.stackTrace,
      );

      return const <Product>[];
    }, (products) => products);

    _hasLoadedProducts = true;
    _isLoadingProducts = false;
    _emitLoaded(_allWorkshops ?? const [], _lastUserLocation);
  }
}
