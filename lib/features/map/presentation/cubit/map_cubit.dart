import 'dart:async';

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
    Duration queryDebounceDuration = const Duration(milliseconds: 300),
  }) : _queryStore = queryStore,
       _queryDebounceDuration = queryDebounceDuration,
       super(const MapInitial()) {
    _queryStore?.addListener(_handleQueryChanged);
  }

  final WorkshopRepository _repository;
  final ProductRepository _productRepository;
  final FeatureLogger _featureLogger;
  final WorkshopDiscoveryQueryStore? _queryStore;
  final Duration _queryDebounceDuration;
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
  int _currentLoadToken = 0;
  Timer? _queryDebounce;

  @override
  Future<void> close() {
    _queryDebounce?.cancel();
    _queryStore?.removeListener(_handleQueryChanged);
    return super.close();
  }

  void _handleQueryChanged() {
    if (isClosed) {
      return;
    }

    _queryDebounce?.cancel();

    if (_queryDebounceDuration == Duration.zero) {
      _emitQueryResults();
      return;
    }

    _queryDebounce = Timer(_queryDebounceDuration, _emitQueryResults);
  }

  void _emitQueryResults() {
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

    final requestLocation = userLocation;
    _lastUserLocation = requestLocation;
    _featureLogger.info(
      feature: 'map',
      action: 'load_workshops_started',
      context: {'hasUserLocation': requestLocation != null},
    );

    final cachedWorkshops = _allWorkshops;
    if (cachedWorkshops != null) {
      final visibleWorkshops = _emitLoaded(cachedWorkshops, requestLocation);
      _featureLogger.info(
        feature: 'map',
        action: 'load_workshops_succeeded',
        context: {
          'totalWorkshops': cachedWorkshops.length,
          'nearbyWorkshops': visibleWorkshops.length,
          'usingFallbackLocation': _searchLocationResolver.isUsingFallback(
            requestLocation,
          ),
          'cached': true,
        },
      );
      return;
    }

    final loadToken = ++_currentLoadToken;

    if (_allWorkshops == null && !isClosed) {
      emit(const MapLoading());
    }

    final result = await _repository.getWorkshops();

    if (isClosed || loadToken != _currentLoadToken) {
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
        final effectiveLocation = requestLocation;
        final nearbyWorkshops = _emitLoaded(workshops, effectiveLocation);

        _featureLogger.info(
          feature: 'map',
          action: 'load_workshops_succeeded',
          context: {
            'totalWorkshops': workshops.length,
            'nearbyWorkshops': nearbyWorkshops.length,
            'usingFallbackLocation': _searchLocationResolver.isUsingFallback(
              effectiveLocation,
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
    if (trimmedQuery.isNotEmpty && !_hasLoadedProducts && !_isLoadingProducts) {
      unawaited(_loadProductsIfNeeded());
    }

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
    return {
      for (final result in productResults) result.workshop.id: result.workshop,
      for (final workshop in workshopResults) workshop.id: workshop,
    }.values.toList(growable: false);
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
