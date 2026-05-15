import 'package:autolab_core/autolab_core.dart';
import 'package:equatable/equatable.dart';

import '../../../core/location/current_location.dart';
import '../../products/domain/services/workshop_product_search_grouper.dart';
import '../../workshops/domain/entities/workshop.dart';

class SearchOverlayState extends Equatable {
  const SearchOverlayState({
    this.query = '',
    this.recentSearches = const <String>[],
    this.workshopResults = const <Workshop>[],
    this.productResults = const <WorkshopProductSearchResult>[],
    this.currentLocation,
    this.isLoadingWorkshops = false,
    this.isLoadingProducts = false,
    this.workshopFailure,
  });

  final String query;
  final List<String> recentSearches;
  final List<Workshop> workshopResults;
  final List<WorkshopProductSearchResult> productResults;
  final CurrentLocation? currentLocation;
  final bool isLoadingWorkshops;
  final bool isLoadingProducts;
  final Failure? workshopFailure;

  bool get hasQuery => query.trim().isNotEmpty;

  bool get isLoading => isLoadingWorkshops || isLoadingProducts;

  SearchOverlayState copyWith({
    String? query,
    List<String>? recentSearches,
    List<Workshop>? workshopResults,
    List<WorkshopProductSearchResult>? productResults,
    CurrentLocation? currentLocation,
    bool clearCurrentLocation = false,
    bool? isLoadingWorkshops,
    bool? isLoadingProducts,
    Failure? workshopFailure,
    bool clearWorkshopFailure = false,
  }) {
    return SearchOverlayState(
      query: query ?? this.query,
      recentSearches: recentSearches ?? this.recentSearches,
      workshopResults: workshopResults ?? this.workshopResults,
      productResults: productResults ?? this.productResults,
      currentLocation: clearCurrentLocation
          ? null
          : currentLocation ?? this.currentLocation,
      isLoadingWorkshops: isLoadingWorkshops ?? this.isLoadingWorkshops,
      isLoadingProducts: isLoadingProducts ?? this.isLoadingProducts,
      workshopFailure: clearWorkshopFailure
          ? null
          : workshopFailure ?? this.workshopFailure,
    );
  }

  @override
  List<Object?> get props => [
    query,
    recentSearches,
    workshopResults,
    productResults,
    currentLocation,
    isLoadingWorkshops,
    isLoadingProducts,
    workshopFailure,
  ];
}
