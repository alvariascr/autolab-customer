import 'dart:async';

import 'package:autolab_core/autolab_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/location/current_location.dart';
import '../../products/domain/entities/product.dart';
import '../../products/domain/repositories/product_repository.dart';
import '../../products/domain/services/product_search_filter.dart';
import '../../products/domain/services/workshop_product_search_grouper.dart';
import '../../workshops/domain/entities/workshop.dart';
import '../../workshops/domain/services/workshop_proximity_filter.dart';
import '../../workshops/domain/services/workshop_text_search_filter.dart';
import 'recent_searches_store.dart';
import 'search_overlay_state.dart';

class SearchOverlayCubit extends Cubit<SearchOverlayState> {
  SearchOverlayCubit({
    ProductRepository? productRepository,
    RecentSearchesStore? recentSearchesStore,
    Duration debounceDuration = const Duration(milliseconds: 240),
    WorkshopTextSearchFilter textSearchFilter =
        const WorkshopTextSearchFilter(),
    WorkshopProximityFilter proximityFilter = const WorkshopProximityFilter(),
    ProductSearchFilter productSearchFilter = const ProductSearchFilter(),
    WorkshopProductSearchGrouper productSearchGrouper =
        const WorkshopProductSearchGrouper(),
  }) : _productRepository = productRepository,
       _recentSearchesStore =
           recentSearchesStore ?? MemoryRecentSearchesStore(),
       _debounceDuration = debounceDuration,
       _textSearchFilter = textSearchFilter,
       _proximityFilter = proximityFilter,
       _productSearchFilter = productSearchFilter,
       _productSearchGrouper = productSearchGrouper,
       super(const SearchOverlayState());

  final ProductRepository? _productRepository;
  final RecentSearchesStore _recentSearchesStore;
  final Duration _debounceDuration;
  final WorkshopTextSearchFilter _textSearchFilter;
  final WorkshopProximityFilter _proximityFilter;
  final ProductSearchFilter _productSearchFilter;
  final WorkshopProductSearchGrouper _productSearchGrouper;

  Timer? _debounce;
  List<Workshop> _workshops = const <Workshop>[];
  List<Product> _products = const <Product>[];
  CurrentLocation? _currentLocation;
  bool _hasLoadedProducts = false;
  bool _isLoadingProducts = false;

  Future<void> initialize({
    required String query,
    required List<Workshop> workshops,
    required CurrentLocation? currentLocation,
    required bool isLoadingWorkshops,
    required Failure? workshopFailure,
  }) async {
    _workshops = workshops;
    _currentLocation = currentLocation;

    if (!isClosed) {
      emit(
        state.copyWith(
          query: query,
          currentLocation: currentLocation,
          clearCurrentLocation: currentLocation == null,
          isLoadingWorkshops: isLoadingWorkshops,
          workshopFailure: workshopFailure,
          clearWorkshopFailure: workshopFailure == null,
        ),
      );
    }

    await _loadRecentSearches();
    _filterNow();
    unawaited(_loadProductsIfNeeded());
  }

  void updateSearchContext({
    required List<Workshop> workshops,
    required CurrentLocation? currentLocation,
    required bool isLoadingWorkshops,
    required Failure? workshopFailure,
  }) {
    _workshops = workshops;
    _currentLocation = currentLocation;

    emit(
      state.copyWith(
        currentLocation: currentLocation,
        clearCurrentLocation: currentLocation == null,
        isLoadingWorkshops: isLoadingWorkshops,
        workshopFailure: workshopFailure,
        clearWorkshopFailure: workshopFailure == null,
      ),
    );
    _filterNow();
  }

  void onQueryChanged(String query) {
    _debounce?.cancel();

    emit(state.copyWith(query: query.trim()));

    _debounce = Timer(_debounceDuration, _filterNow);
    unawaited(_loadProductsIfNeeded());
  }

  Future<void> commitSearch(String query) async {
    final recentSearches = await _recentSearchesStore.save(query);

    if (!isClosed) {
      emit(state.copyWith(recentSearches: recentSearches));
    }
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  Future<void> _loadRecentSearches() async {
    final recentSearches = await _recentSearchesStore.load();

    if (!isClosed) {
      emit(state.copyWith(recentSearches: recentSearches));
    }
  }

  Future<void> _loadProductsIfNeeded() async {
    final productRepository = _productRepository;

    if (productRepository == null ||
        _hasLoadedProducts ||
        _isLoadingProducts ||
        isClosed) {
      return;
    }

    _isLoadingProducts = true;

    if (state.hasQuery) {
      emit(state.copyWith(isLoadingProducts: true));
    }

    final result = await productRepository.getActiveProducts();

    if (isClosed) {
      return;
    }

    _products = result.fold((_) => const <Product>[], (products) => products);
    _hasLoadedProducts = true;
    _isLoadingProducts = false;

    emit(state.copyWith(isLoadingProducts: false));
    _filterNow();
  }

  void _filterNow() {
    if (isClosed) {
      return;
    }

    final query = state.query.trim();
    final searchableWorkshops = _searchableWorkshops();

    if (query.isEmpty) {
      emit(
        state.copyWith(
          workshopResults: const <Workshop>[],
          productResults: const <WorkshopProductSearchResult>[],
        ),
      );
      return;
    }

    final workshopResults = _textSearchFilter.filter(
      workshops: searchableWorkshops,
      query: query,
    );
    final matchingProducts = _productSearchFilter.filter(
      products: _products,
      query: query,
    );
    final productResults = _productSearchGrouper.group(
      products: matchingProducts,
      workshops: searchableWorkshops,
    );

    emit(
      state.copyWith(
        workshopResults: workshopResults,
        productResults: productResults,
        isLoadingProducts: query.isNotEmpty && _isLoadingProducts,
      ),
    );
  }

  List<Workshop> _searchableWorkshops() {
    final currentLocation = _currentLocation;

    if (currentLocation == null) {
      return _workshops;
    }

    return _proximityFilter.filterNearby(
      workshops: _workshops,
      currentLocation: currentLocation,
    );
  }
}
